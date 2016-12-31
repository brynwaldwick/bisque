Biscuit = require './biscuit'

BisquePeer = class BisquePeer

    initializeBisque: (reward_threshold) ->
        @biscuit_creators = {}
        @biscuit_deliverers = {}
        @reward_threshold = reward_threshold
        @buildDenominator()

    buildDenominator: ->
        denominator = 0
        _i = @reward_threshold
        while _i > 0
            denominator += _i
            _i--
        @denominator = denominator

    onMessage: (message) ->
        console.log "[#{@username}: i got a message", message

        _num_deliverers = @messages[message.id].peers?.length

        if _num_deliverers < @reward_threshold
            _b = new Biscuit 1/Math.pow(2,_num_deliverers-1), message.id, @id
            @sendBiscuit _b, message.from

    onBiscuit: (biscuit) ->
        console.log "[#{@username}: i got a biscuit", biscuit
        {N, message_id, creator_id, from} = biscuit
        @biscuit_creators[creator_id] ||= []
        @biscuit_creators[creator_id].push biscuit

        @biscuit_deliverers[from] || = []
        @biscuit_deliverers[from].push biscuit

        deliverers = @findDeliverers message_id, @reward_threshold

        deliverers.map (d_id, _i) =>
            i = @reward_threshold - _i
            _N = (i * N) / @denominator
            _b = new Biscuit _N, message_id, creator_id
            @sendBiscuit _b, d_id

    findDeliverers: (message_id, i) ->
        (@messages[message_id]?.peers || []).slice(0, i-1)

    sendBiscuit: (biscuit, peer_id) ->
        peer = @peers[peer_id]
        biscuit.from = @id
        @sendMessageToPeer {kind: 'biscuit', biscuit}, peer_id

module.exports = BisquePeer
