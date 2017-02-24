Db = require './db'
{randomChoice, objectMatcher} = require './helpers'

VANILLA_IDS = []

fixNumbers = (o) ->
    for k, v of o
        if (k == 'id' or k.match /_id$/) && !(k in VANILLA_IDS)
            o[k] = Number v

class LocalDb extends Db
    collections:
        peers: []
        connections: []
        messages: []
        biscuits: []

    _get: (type, query, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        fixNumbers query
        # console.log '[LocalDb._get]', type, query
        item = @collections[type].filter(objectMatcher query)[0]
        cb null, item

    _find: (type, query, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        fixNumbers query
        # console.log '[LocalDb._find]', type, query
        items = @collections[type].filter objectMatcher query
        cb null, items

    _create: (type, new_item, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        fixNumbers new_item
        new_item.id = @collections[type].length + 1
        @collections[type].push new_item
        cb null, new_item

    _update: (type, id, item_update, cb) ->
        if !@collections[type]?
            return cb "No such collection #{type}"
        id = Number id
        fixNumbers item_update
        item = @collections[type].filter((i) -> i.id == id)[0]
        Object.assign item, item_update
        cb null, item

    _findByIds: (type, item_ids, cb) ->
        item_ids = item_ids.map (i) -> Number i
        items = @collections[type].filter((i) -> i.id in item_ids)
        cb null, items

    _findWithArray: (type, queries, cb) ->
        found = []
        for item in  @collections[type]
            matches = false
            for query in queries
                if objectMatcher(query)(item)
                    matches = true
            if matches
                found.push item
        cb null, found

    _remove: (type, id, cb) ->
        id = Number id
        # console.log '[LocalDb._remove]', type, id
        @collections[type] = @collections[type].filter((i) -> i.id != id)
        cb null, true

module.exports = LocalDb
