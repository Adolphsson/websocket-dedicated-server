const { uuidToUsername } = require('./dataHandler');

//This script defines the state of the server and keeps all users updated, here you'll store which players are online, their position and whatever you want more.
let worldState = {};
let playerStateCollection = {
    'Bengt': {
        'A': 'idle',
        'D': ["down",false,{"body":"fat","bottoms":4,"eyes":5,"hairstyles":2,"mouths":1,"shoes":2,"top":1}],
        'P': "(5, 5)",
        'T': 'npc'
    }
};

//Whenever the player sends their data, it stores in the matching state collection.
const updatePlayerState = (playerId, playerState) => {
    if (playerStateCollection[playerId]) {
        playerStateCollection[playerId] = playerState;
    } else {
        playerStateCollection[playerId] = playerState;
    }
};

//Broadcast the current world state to all the peers.
function broadcastWorldState(wss){
    //TODO: This kind of broadcast can be very costly, try to make it location dependant and only send the update to players within viewing distance of each other 
    wss.clients.forEach(client => {
            client.send(JSON.stringify({action:'receive_world_state', data: worldState}));
        });
    };

//This is where all the checks go before broadcasting the world state to all peers.
function stateProcess(wss, clients){
    if (Object.keys(playerStateCollection).length > 0) {
        worldState = playerStateCollection
        for (let playerId in worldState) {
            delete worldState[playerId].T
            for (const property in clients) {
                if (uuidToUsername[property] === playerId) {
                    worldState[playerId].ID = clients[property].peerID;
                    break;
                }
            }
        }
        worldState.T = Date.now();
		//Verifications
		//Anti-Cheat
		//Cuts
		//Physics checks
		//Anything we might need
        broadcastWorldState(wss)
}};

module.exports = { updatePlayerState, stateProcess, playerStateCollection };
