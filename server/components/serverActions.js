//You can add all the actions that clients can request here.
const { loadPlayerData, loadMapData, loadPlayerInventory, protoMessage } = require('./dataHandler');
const { updatePlayerState } = require('./stateProcessing');
const { getChatResponseAsync } = require('./npcProcessing');
const { uuidToUsername } = require('./dataHandler');

//Here the server will match the uuid with the username, load the player data and send it back so the client can restore.
function readyPlayer(wss, ws, parsed, clients) {
    for (let id in uuidToUsername){
        if (parsed.data.username == uuidToUsername[id]){
            ws.send(protoMessage(CMD.PING.id, 0, {message: 'Already connected...'}));
            ws.close()
            return
        }
    }
    uuidToUsername[ws.playerUUID] = parsed.data.username;
    const data = {userData: loadPlayerData(parsed.data.username), playerUUID: ws.playerUUID, playerID: ws.peerID};
    if (data) ws.send(protoMessage(CMD.BROADCAST.id, 0, {function:'load_player_state',parameters:data}));
}

//This function will receive the player's current state, such as position, animation and etc, and it will send to all the other players online via updatePlayerState().
function receivePlayerState(wss, ws, parsed, clients) {
    updatePlayerState(uuidToUsername[ws.playerUUID], parsed.data);
}

//This script you can use to send fast packages between players, without the need of running any backend function. All you need is create the action in the client.
function broadcast(wss, ws, parsed, clients){
    if(parsed.data.parameters.position) {
        var position = parsed.data.parameters.position.replace('(', '').replace(')', '').split(',');
        for (var i = 0; i < position.length; i++) {
            position[i] = parseFloat(position[i]);
        }
        var npcPos = [5,5];
        var npcDeltaPos = [Math.abs(position[0] - npcPos[0]), Math.abs(position[1] - npcPos[1])];
        
        if(parsed.data.function === 'receive_text' && parsed.data.parameters.username !== 'Bengt' && Math.sqrt((npcDeltaPos[0]*npcDeltaPos[0]) + (npcDeltaPos[1]*npcDeltaPos[1])) < 50.0) {
            // A chat message is being sent, let's read it and send it to chatGPT for a response
            getChatResponseAsync(parsed.data.parameters.username, parsed.data.parameters.text).then(msg => {
                wss.clients.forEach(client => {
                    client.send(protoMessage(CMD.BROADCAST.id, 0, {action:'broadcast', data: {function: 'receive_text', parameters: {username: 'Bengt', text: msg, position: '(' + npcPos[0].toString() + ',' + npcPos[1].toString() + ')', audioIndex: Math.round(Math.random()*6)}}}));
                });
            });
        }
    }

    //TODO: This kind of broadcast can be very costly, try to make it location dependant and only send the update to players within viewing distance of each other
    wss.clients.forEach(client => {
        client.send(protoMessage(CMD.BROADCAST.id, 0, parsed.data));
   });
};

//This function will respond to the client that send the request and can be used to measure the round trip time.
function ping(wss, ws, parsed, clients){
    ws.send(protoMessage(CMD.PING.id, 0, parsed.data));
};

function signaling(wss, ws, parsed, clients) {
    getSignalResponse(wss, ws, parsed.data, clients);
}

module.exports = { readyPlayer, receivePlayerState, broadcast, ping, signaling };
