const STR_INVALID_DEST = 'Invalid destination';
const STR_INVALID_CMD = 'Invalid command';

const CMD = {
	JOIN: 0, // eslint-disable-line sort-keys
	ID: 1, // eslint-disable-line sort-keys
	PEER_CONNECT: 2, // eslint-disable-line sort-keys
	PEER_DISCONNECT: 3, // eslint-disable-line sort-keys
	OFFER: 4, // eslint-disable-line sort-keys
	ANSWER: 5, // eslint-disable-line sort-keys
	CANDIDATE: 6, // eslint-disable-line sort-keys
	SEAL: 7, // eslint-disable-line sort-keys
};

function ProtoMessage(type, id, data) {
	return JSON.stringify(
        {
            action: 'signaling',
            data: {
		        'type': type,
		        'id': id,
		        'data': data || '',
	        }
        });
}

class ProtoError extends Error {
	constructor(code, message) {
		super(message);
		this.code = code;
	}
}

function parseMsg(ws, json, clients) {
	const type = typeof (json['type']) === 'number' ? Math.floor(json['type']) : -1;
	const id = typeof (json['id']) === 'number' ? Math.floor(json['id']) : -1;
	const data = typeof (json['data']) === 'string' ? json['data'] : '';

	if (type === CMD.OFFER || type === CMD.ANSWER || type === CMD.CANDIDATE) {
        let dest = null;
        for (const property in clients) {
            if (clients[property].peerID == id) {
                dest = clients[property];
                break;
            }
        }
		if (!dest) {
			throw new ProtoError(4000, STR_INVALID_DEST);
		}
		dest.send(ProtoMessage(type, ws.peerID, data));
		return;
	}
	throw new ProtoError(4000, STR_INVALID_CMD);
}

async function getSignalResponse(wss, ws, msg) {
    try {
        parseMsg(ws, msg);
    } catch (e) {
        const code = e.code || 4000;
        console.log(`Error parsing message from ${ws.peerID}:\n${
            message}`);
        ws.close(code, e.message);
    }
}

module.exports = { getSignalResponse };