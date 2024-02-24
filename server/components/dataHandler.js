//This script save and load player's data.
const fs = require('fs');
const path = require('path');
const uuidToUsername = {};

const CMD = {
    ERROR: {id:0}, // eslint-disable-line sort-keys
    BROADCAST: {id:1}, // eslint-disable-line sort-keys
    WORLD_STATE: {id:2}, // eslint-disable-line sort-keys
    PLAYER_STATE: {id:3}, // eslint-disable-line sort-keys
    PING: {id:4}, // eslint-disable-line sort-keys
    READY_PLAYER: {id:5}, // eslint-disable-line sort-keys
	JOIN: {id:6}, // eslint-disable-line sort-keys
	ID: {id:7}, // eslint-disable-line sort-keys
	PEER_CONNECT: {id:8}, // eslint-disable-line sort-keys
	PEER_DISCONNECT: {id:9}, // eslint-disable-line sort-keys
	OFFER: {id:10}, // eslint-disable-line sort-keys
	ANSWER: {id:11}, // eslint-disable-line sort-keys
	CANDIDATE: {id:12}, // eslint-disable-line sort-keys
	SEAL: {id:13}, // eslint-disable-line sort-keys
    ASSIGNED_ID: {id:14}, // eslint-disable-line sort-keys
};

const savePlayerData = (username, data) => {
    try {
        delete data["A"]
        delete data["T"]
        const filePath = path.join(__dirname, `./player_data/${username}.json`);
        fs.writeFileSync(filePath, JSON.stringify(data));
    } catch (error){
        console.error("Error: ", error)
    }
};

const loadPlayerData = (username) => {
    const filePath = path.join(__dirname, `./player_data/${username}.json`);
    if (fs.existsSync(filePath)) {
        return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
    }
    return null;
};

function protoMessage(type, id, data) {
	return JSON.stringify({
        'type': type,
        'id': id,
        'data': data || '',
    });
}

module.exports = { savePlayerData, loadPlayerData ,uuidToUsername, protoMessage, CMD };
