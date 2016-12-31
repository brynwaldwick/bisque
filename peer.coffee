Biscuit = require './biscuit'

BisquePeer = class BisquePeer

    biscuit_creators = {}
    biscuit_deliverers = {}

    constructor: (@threshold=2) ->
        _i = biscuit_thresh

        # Build the denominator for normalized N biscuit distribution
        denominator = 0
        while _i > 0
            denominator += _i
            _i--
        @denominator = denominator

    onMessage: (message) ->
        console.log 'i got a message', message

        _num_deliverers = @messages[message.id].peers?.length
        if _num_deliverers < @threshold
            _b = new Biscuit 1/Math.pow(2,_num_deliverers), message.id, @id
            _b.from = @id
            @sendBiscuit _b, message.from

    onBiscuit: (biscuit) ->
        {N, message_id, creator_id, from} = biscuit
        @biscuit_creators[creator_id] ||= []
        @biscuit_creators[creator_id].push biscuit

        @biscuit_deliverers[from] || = []
        @biscuit_deliverers[from].push biscuit

        deliverers = @findDeliverers message_id, @threshold
        deliverers.map (d, _i) =>
            i = @threshold - _i
            _N = i / @denominator
            _b = new Biscuit _N, message_id, creator_id
            @sendBiscuit _b, d.id

    findDeliverers: (message_id, i) ->
        (@messages[message_id]?.peers || []).slice(0, i-1)

    sendBiscuit: (biscuit, peer_id) ->
        peer = @peers[peer_id]
        @sendMessageToPeer {kind: 'biscuit', biscuit}

module.exports = BisquePeer
