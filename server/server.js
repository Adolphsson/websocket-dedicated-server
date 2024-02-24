//This is the main script for the server.
const express = require('express');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid'); 
const crypto = require('crypto');

const { savePlayerData, uuidToUsername } = require('./components/dataHandler');
const { stateProcess, playerStateCollection } = require('./components/stateProcessing');
const { readyPlayer, broadcast, receivePlayerState, ping } = require('./components/serverActions');

const app = express();
app.use ('/healthcheck', require ('express-healthcheck')({
    healthy: function () {
        return {
            uptime: process.uptime(), 
            players: Object.keys(clients).length
        };
    }
}));

//Start server
const MAX_PEERS = 4096;
const PORT = '8080'

const MAX_LOBBIES = 1024;
const ALFNUM = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

const NO_LOBBY_TIMEOUT = 1000;
const SEAL_CLOSE_TIMEOUT = 10000;
const PING_INTERVAL = 10000;

const STR_NO_LOBBY = 'Have not joined lobby yet';
const STR_HOST_DISCONNECTED = 'Room host has disconnected';
const STR_ONLY_HOST_CAN_SEAL = 'Only host can seal the lobby';
const STR_SEAL_COMPLETE = 'Seal complete';
const STR_TOO_MANY_LOBBIES = 'Too many lobbies open, disconnecting';
const STR_ALREADY_IN_LOBBY = 'Already in a lobby';
const STR_LOBBY_DOES_NOT_EXISTS = 'Lobby does not exists';
const STR_LOBBY_IS_SEALED = 'Lobby is sealed';
const STR_INVALID_FORMAT = 'Invalid message format';
const STR_NEED_LOBBY = 'Invalid message when not in a lobby';
const STR_SERVER_ERROR = 'Server error, lobby not found';
const STR_INVALID_DEST = 'Invalid destination';
const STR_INVALID_CMD = 'Invalid command';
const STR_TOO_MANY_PEERS = 'Too many peers connected';
const STR_INVALID_TRANSFER_MODE = 'Invalid transfer mode, must be text';

const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server started on port ${PORT}`);
});

const wss = new WebSocket.Server({ server });
const clients = {};

//Anything the user can call via client, should be added in the actionHandlers const below.
const CMD = {
    ERROR: {id:0,func:null}, // eslint-disable-line sort-keys
    BROADCAST: {id:1,func:(wss, ws, parsed, clients) => broadcast(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
    WORLD_STATE: {id:2,func:null}, // eslint-disable-line sort-keys
    PLAYER_STATE: {id:3,func:(wss, ws, parsed, clients) => receivePlayerState(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
    PING: {id:4,func:(wss, ws, parsed, clients) => ping(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
    READY_PLAYER: {id:5,func:(wss, ws, parsed, clients) => readyPlayer(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
	JOIN: {id:6,func:(wss, ws, parsed, clients) => signalHandling(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
	ID: {id:7,func:(wss, ws, parsed, clients) => signalHandling(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
	PEER_CONNECT: {id:8,func:(wss, ws, parsed, clients) => signalHandling(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
	PEER_DISCONNECT: {id:9,func:(wss, ws, parsed, clients) => signalHandling(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
	OFFER: {id:10,func:(wss, ws, parsed, clients) => signalHandling(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
	ANSWER: {id:11,func:(wss, ws, parsed, clients) => signalHandling(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
	CANDIDATE: {id:12,func:(wss, ws, parsed, clients) => signalHandling(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
	SEAL: {id:13,func:(wss, ws, parsed, clients) => signalHandling(wss, ws, parsed, clients)}, // eslint-disable-line sort-keys
    ASSIGNED_ID: {id:14,func:null}, // eslint-disable-line sort-keys
};

function randomInt(low, high) {
	return Math.floor(Math.random() * (high - low + 1) + low);
}

function randomId() {
	return Math.abs(new Int32Array(crypto.randomBytes(4).buffer)[0]);
}

function randomSecret() {
	let out = '';
	for (let i = 0; i < 16; i++) {
		out += ALFNUM[randomInt(0, ALFNUM.length - 1)];
	}
	return out;
}

function ProtoMessage(type, id, data) {
	return JSON.stringify({
        'type': type,
        'id': id,
        'data': data || '',
    });
}

class ProtoError extends Error {
	constructor(code, message) {
		super(message);
		this.code = code;
	}
}

class Peer {
	constructor(id, ws) {
		this.id = id;
		this.ws = ws;
		this.lobby = '';
		// Close connection after 1 sec if client has not joined a lobby
		this.timeout = setTimeout(() => {
			if (!this.lobby) {
				ws.close(4000, STR_NO_LOBBY);
			}
		}, NO_LOBBY_TIMEOUT);
	}
}

class Lobby {
	constructor(name, host, mesh) {
		this.name = name;
		this.host = host;
		this.mesh = mesh;
		this.peers = [];
		this.sealed = false;
		this.closeTimer = -1;
	}

	getPeerId(peer) {
		if (this.host === peer.id) {
			return 1;
		}
		return peer.id;
	}

	join(peer) {
		const assigned = this.getPeerId(peer);
		peer.ws.send(ProtoMessage(CMD.ID.id, assigned, this.mesh ? 'true' : ''));
		this.peers.forEach((p) => {
			p.ws.send(ProtoMessage(CMD.PEER_CONNECT.id, assigned));
			peer.ws.send(ProtoMessage(CMD.PEER_CONNECT.id, this.getPeerId(p)));
		});
		this.peers.push(peer);
	}

	leave(peer) {
		const idx = this.peers.findIndex((p) => peer === p);
		if (idx === -1) {
			return false;
		}
		const assigned = this.getPeerId(peer);
		const close = assigned === 1;
		this.peers.forEach((p) => {
			if (close) { // Room host disconnected, must close.
				p.ws.close(4000, STR_HOST_DISCONNECTED);
			} else { // Notify peer disconnect.
				p.ws.send(ProtoMessage(CMD.PEER_DISCONNECT.id, assigned));
			}
		});
		this.peers.splice(idx, 1);
		if (close && this.closeTimer >= 0) {
			// We are closing already.
			clearTimeout(this.closeTimer);
			this.closeTimer = -1;
		}
		return close;
	}

	seal(peer) {
		// Only host can seal
		if (peer.id !== this.host) {
			throw new ProtoError(4000, STR_ONLY_HOST_CAN_SEAL);
		}
		this.sealed = true;
		this.peers.forEach((p) => {
			p.ws.send(ProtoMessage(CMD.SEAL.id, 0));
		});
		console.log(`Peer ${peer.id} sealed lobby ${this.name} `
			+ `with ${this.peers.length} peers`);
		this.closeTimer = setTimeout(() => {
			// Close peer connection to host (and thus the lobby)
			this.peers.forEach((p) => {
				p.ws.close(1000, STR_SEAL_COMPLETE);
			});
		}, SEAL_CLOSE_TIMEOUT);
	}
}

const lobbies = new Map();
let peersCount = 0;

function joinLobby(peer, pLobby, mesh) {
	let lobbyName = pLobby;
	if (lobbyName === '') {
		if (lobbies.size >= MAX_LOBBIES) {
			throw new ProtoError(4000, STR_TOO_MANY_LOBBIES);
		}
		// Peer must not already be in a lobby
		if (peer.lobby !== '') {
			throw new ProtoError(4000, STR_ALREADY_IN_LOBBY);
		}
		lobbyName = randomSecret();
		lobbies.set(lobbyName, new Lobby(lobbyName, peer.id, mesh));
		console.log(`Peer ${peer.id} created lobby ${lobbyName}`);
		console.log(`Open lobbies: ${lobbies.size}`);
	}
	const lobby = lobbies.get(lobbyName);
	if (!lobby) {
		throw new ProtoError(4000, STR_LOBBY_DOES_NOT_EXISTS);
	}
	if (lobby.sealed) {
		throw new ProtoError(4000, STR_LOBBY_IS_SEALED);
	}
	peer.lobby = lobbyName;
	console.log(`Peer ${peer.id} joining lobby ${lobbyName} `
		+ `with ${lobby.peers.length} peers`);
	lobby.join(peer);
	peer.ws.send(ProtoMessage(CMD.JOIN.id, 0, lobbyName));
}

function signalHandling(wss, peer, json, clients) {
    const type = typeof (json['type']) === 'number' ? Math.floor(json['type']) : -1;
    const id = typeof (json['id']) === 'number' ? Math.floor(json['id']) : -1;
    const data = typeof (json['data']) === 'string' ? json['data'] : '';

    if (type < 0|| id < 0) {
        throw new ProtoError(4000, STR_INVALID_FORMAT);
    }
    
    // Lobby joining.
	if (type === CMD.JOIN.id) {
		joinLobby(peer, data, id === 0);
		return;
	}

	if (!peer.lobby) {
		throw new ProtoError(4000, STR_NEED_LOBBY);
	}
	const lobby = lobbies.get(peer.lobby);
	if (!lobby) {
		throw new ProtoError(4000, STR_SERVER_ERROR);
	}

	// Lobby sealing.
	if (type === CMD.SEAL.id) {
		lobby.seal(peer);
		return;
	}

	// Message relaying format:
	//
	// {
	//   "type": CMD.[OFFER|ANSWER|CANDIDATE],
	//   "id": DEST_ID,
	//   "data": PAYLOAD
	// }
	if (type === CMD.OFFER.id || type === CMD.ANSWER.id || type === CMD.CANDIDATE.id) {
		let destId = id;
		if (id === 1) {
			destId = lobby.host;
		}
		const dest = lobby.peers.find((e) => e.id === destId);
		// Dest is not in this room.
		if (!dest) {
			throw new ProtoError(4000, STR_INVALID_DEST);
		}
		dest.ws.send(ProtoMessage(type, lobby.getPeerId(peer), data));
		return;
	}
    throw new ProtoError(4000, STR_INVALID_CMD);
}

wss.on('connection', (ws, req) => {
    if (Object.keys(clients).length >= MAX_PEERS) {
		ws.close(4000, STR_TOO_MANY_PEERS);
		return;
	}

    peersCount++;
    const id = randomId();
    const peer = new Peer(id, ws);

    ws.playerUUID = uuidv4();  //Attach UUID directly to the websocket connection.
    ws.peerID = id;
    clients[ws.playerUUID] = ws;
    ws.send(ProtoMessage(CMD.ASSIGNED_ID.id, 0, { uuid: ws.playerUUID, id: ws.peerID }));

    ws.on('message', (data, isBinary) => {
        const message = isBinary ? data : data.toString();
        
        if (typeof message === 'string') {
            try {
                //All the messages received should be in this format: {action:actionHandler, data:data}.
                const parsed = JSON.parse(message);

                const typeHandler = actionHandlers[type];
                if (typeHandler) {
                    if(typeHandler.func) {
                        try {
                            typeHandler.func(wss, ws, parsed, clients);
                        } catch (e) {
                            const code = e.code || 4000;
                            console.log(`Error handling ${parsed.action} from ${ws.peerID}. Data:\n${message}`);
                            ws.close(code, e.message);
                        }
                    }
                    else {
                        //ws.send(JSON.stringify({ status: 'error', message: 'Type is one way only' }));
                        ws.send(ProtoMessage(CMD.ERROR.id, 0, { message: 'Type is one way only' }));
                    }
                }
                else {
                    //ws.send(JSON.stringify({ status: 'error', message: 'Invalid type' }));
                    ws.send(ProtoMessage(CMD.ERROR.id, 0, { message: 'Invalid type' }));
                }
            } catch (e) {
                const code = e.code || 4000;
                console.log(`Error parsing message from ${ws.peerID}:\n${
                    message}`);
                ws.close(code, e.message);
            }
        }
        else {
            console.log('Message type: ' + typeof message)
            if (typeof message === 'object') {
                console.log('Object is: ' + JSON.stringify(message))
            }
            ws.close(4000, STR_INVALID_TRANSFER_MODE);
        }
    });

    //Whenever the user closes the connection, it saves its state collection, broadcast to all other players that the player left and delete its state collection and uuid.
    ws.on('close', (code, data) => {
        peersCount--;
        console.log(`Connection with peer ${peer.id} closed `
			+ `with reason ${code}: ${reason}`);
		if (peer.lobby && lobbies.has(peer.lobby)
			&& lobbies.get(peer.lobby).leave(peer)) {
			lobbies.delete(peer.lobby);
			console.log(`Deleted lobby ${peer.lobby}`);
			console.log(`Open lobbies: ${lobbies.size}`);
			peer.lobby = '';
		}
		if (peer.timeout >= 0) {
			clearTimeout(peer.timeout);
			peer.timeout = -1;
		}

        //const reason = data.toString();
        //console.log(`User disconnected: ${reason}`);
        if (uuidToUsername[ws.playerUUID] && playerStateCollection[uuidToUsername[ws.playerUUID]]) {
            savePlayerData(uuidToUsername[ws.playerUUID], playerStateCollection[uuidToUsername[ws.playerUUID]]);
            broadcast(wss, ws, {data:{function:'despawn_player', parameters:{username:uuidToUsername[ws.playerUUID]}}})
            delete playerStateCollection[uuidToUsername[ws.playerUUID]]
            delete uuidToUsername[ws.playerUUID];
        }

        delete clients[ws.playerUUID];
    });

    ws.on('error', (error) => {
		console.error(error);
	});
});

setInterval(() => {
    stateProcess(wss, clients); //Here you'll run the server state processing, which will keep the game synched.
    //You can run anything else below.

}, 100);

