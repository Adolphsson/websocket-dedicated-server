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

const STR_TOO_MANY_PEERS = 'Too many peers connected';
const STR_INVALID_TRANSFER_MODE = 'Invalid transfer mode, must be text';

const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server started on port ${PORT}`);
});

const wss = new WebSocket.Server({ server });
const clients = {};

//Anything the user can call via client, should be added in the actionHandlers const below.
const actionHandlers = {
    'readyPlayer': (wss, ws, parsed, clients) => readyPlayer(wss, ws, parsed, clients),
    'receivePlayerState': (wss, ws, parsed, clients) => receivePlayerState(wss, ws, parsed, clients),
    'broadcast': (wss, ws, parsed, clients) => broadcast(wss, ws, parsed, clients),
    'ping': (wss, ws, parsed, clients) => ping(wss, ws, parsed, clients),
    'signaling': (wss, ws, parsed, clients) => signaling(wss, ws, parsed, clients),
};

function randomId() {
	return Math.abs(new Int32Array(crypto.randomBytes(4).buffer)[0]);
}

wss.on('connection', (ws, req) => {
    if (Object.keys(clients).length >= MAX_PEERS) {
		ws.close(4000, STR_TOO_MANY_PEERS);
		return;
	}

    ws.playerUUID = uuidv4();  //Attach UUID directly to the websocket connection.
    ws.peerID = randomId();
    clients[ws.playerUUID] = ws;
    ws.send(JSON.stringify({ action: 'assignUUID', uuid: ws.playerUUID, id: ws.peerID }));

    ws.on('message', (message) => {
        /*if (typeof message === 'object') {
            if (message.type === 'Buffer') {
                //message.data
            }
            else {
                ws.close(4000, STR_INVALID_TRANSFER_MODE);
			    return;
            }
        }

        if (typeof message !== 'string') {
            console.log('Message type: ' + typeof message)
            if (typeof message === 'object') {
                console.log('Object is: ' + JSON.stringify(message))
            }
			//ws.close(4000, STR_INVALID_TRANSFER_MODE);
			//return;
		}*/
        if (typeof message === 'string') {
            try {
                //All the messages received should be in this format: {action:actionHandler, data:data}.
                const parsed = JSON.parse(message);

                const actionHandler = actionHandlers[parsed.action];
                if (actionHandler) {
                    actionHandler(wss, ws, parsed, clients);
                }
                else {
                    ws.send(JSON.stringify({ status: 'error', message: 'Invalid action' }));
                }
            } catch (e) {
                const code = e.code || 4000;
                console.log(`Error parsing message from ${ws.peerID}:\n${
                    message}`);
                ws.close(code, e.message);
            }
        }
    });

    //Whenever the user closes the connection, it saves its state collection, broadcast to all other players that the player left and delete its state collection and uuid.
    ws.on('close', () => {
        if (uuidToUsername[ws.playerUUID] && playerStateCollection[uuidToUsername[ws.playerUUID]]) {
            savePlayerData(uuidToUsername[ws.playerUUID], playerStateCollection[uuidToUsername[ws.playerUUID]]);
            broadcast(wss,ws, {data:{function:'despawn_player', parameters:{username:uuidToUsername[ws.playerUUID]}}})
            delete playerStateCollection[uuidToUsername[ws.playerUUID]]
            delete uuidToUsername[ws.playerUUID];
        }

        delete clients[ws.playerUUID];
    });
});

setInterval(() => {
    stateProcess(wss); //Here you'll run the server state processing, which will keep the game synched.
    //You can run anything else below.

}, 100);

