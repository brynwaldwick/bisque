util = require 'util'
BisquePeer = require './peer'

somata = require 'somata'
client = new somata.Client
Monitor = client.remote.bind client, 'bisque:data'

Peers = {}

class TestPeer extends BisquePeer

    constructor: (@id, @username, @reward_threshold=3) ->
        @peers = {}
        @messages = {}
        @biscuits = []
        @initializeBisque(@reward_threshold)
        return @

    sendMessageToPeer: (message, peer_id) ->
        sendMessage @id, peer_id, message

connectPeers = (peer_a_id, peer_b_id) ->

    _p_a = {id: peer_a_id, username: Peers[peer_a_id].username}
    _p_b = {id: peer_b_id, username: Peers[peer_b_id].username}

    console.log 'Connecting peers', _p_a, 'and', _p_b
    Monitor 'create', 'connections', {from_peer_id: peer_a_id, to_peer_id: peer_b_id}, ->
    Peers[peer_a_id].peers[peer_b_id] ||= _p_b
    Peers[peer_b_id].peers[peer_a_id] ||= _p_a

createPeer = (id, username) ->
    _p = new TestPeer id, username
    Monitor 'create', 'peers', {id, username}, ->
    Peers[id] = _p

sendMessage = (peer_a_id, peer_b_id, message) ->
#     # if connected, send message
#     # if not, throw error "no connection exists"
    message.from = peer_a_id
    Monitor 'create', 'messages', {from: peer_a_id, from_peer_id: peer_a_id, to_peer_id: peer_b_id, body: message.body, id: message.id, kind: message.kind}, (err, created) ->
        console.log 'i send a message', message
        if Peers[peer_a_id]?.peers[peer_b_id]?.id?
            if message.kind == 'biscuit'
                Peers[peer_b_id].biscuits.push message.biscuit
                Peers[peer_b_id].onBiscuit message.biscuit
                Monitor 'create', 'biscuits', {message_id: created.id, source_message_id: message.biscuit.message_id, magnitude: message.biscuit.N, to_peer_id: peer_b_id, from_peer_id: peer_a_id}, ->
            else if Peers[peer_b_id].messages[message.id]?
                Peers[peer_b_id].messages[message.id].peers.push peer_a_id

            else
                message.peers = [peer_a_id]
                Peers[peer_b_id].messages[message.id] = message
                Peers[peer_b_id].onMessage message

        else
            console.log 'The connection doesnt exist'


createPeer 1, 'testjones-1'
createPeer 2, 'testjones-2'
createPeer 3, 'testjones-3'
createPeer 4, 'testjones-4'

connectPeers 1, 2
connectPeers 1, 3
connectPeers 2, 3
connectPeers 3, 4

sendMessage 1, 2, {kind: 'message', body: 'Test Jones', id: '1234'}
sendMessage 2, 3, {kind: 'message', body: 'Test Jones', id: '1234'}
sendMessage 1, 3, {kind: 'message', body: 'Test Jones', id: '1234'}
sendMessage 3, 4, {kind: 'message', body: 'Test Jones', id: '1234'}

console.log Peers[1].biscuits

# send message from 1 to 2
    # biscuit from 2 to 1
# send message from 1 to 3
    # biscuit from 3 to 1
# send message from 2 to 3
    # biscuit from 3 to 2
        # N biscuit from 2 to 1




# seeing on a peer > how they rank the other peers
# giving a button to send a message to the highest ranked peer ->
#     or type in a peer id and see if it will recommend who it should send to based on its biscuit trail

