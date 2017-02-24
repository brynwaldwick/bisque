async = require 'async'
{isNullObject, hasNullKeys} = require './helpers'

class Db
    constructor: (@schema) ->
        console.log "Created #{@constructor.name} with schema:"
        for type, definition of @schema
            console.log " * #{type}"

    bindPublisher: (publisher) ->
        @publisher = publisher

    get: (type, query, cb) ->
        # console.log '[Db.get]', type, query
        if isNullObject query
            return cb "Missing required field 'query'"
        else if hasNullKeys query
            return cb "Query has null keys"
        else
            primary_type = type.split('.')[0]
            @_get primary_type, query, cb

    find: (type, query, cb) ->
        # console.log '[Db.find]', type, query
        primary_type = type.split('.')[0]
        @_find primary_type, query, cb

    findWithArray: (type, queries, cb) ->
        # console.log '[Db.findWithArray]', type, queries
        primary_type = type.split('.')[0]
        @_findWithArray primary_type, queries, cb

    create: (type, new_item, cb) ->
        @schema[type]?.preCreate?(new_item)
        @_create type, new_item, (err, created_item) =>
            if err?
                return cb err
            @get type, {id: created_item.id}, (err, created_item) =>
                @schema[type]?.postCreate?(created_item)
                new_event = {
                    type
                    kind: 'created'
                    item: created_item
                }
                @publisher?.publish "#{type}:created", new_event
                cb err, created_item

    update: (type, id, item_update, cb) ->
        if !id?
            return cb "Missing required field 'id'"
        else
            @_update type, id, item_update, (err, updated_item) =>
                @get type, {id}, (err, item) ->
                    new_event = {
                        type
                        kind: 'updated'
                        update: item_update
                        item: item
                    }
                    @publisher?.publish "#{type}:updated", new_event
                    @publisher?.publish "#{type}:#{id}:updated", new_event

    remove: (type, id, cb) ->
        @_remove type, id, cb

    bindAll: ->
        get: @get.bind @
        find: @find.bind @
        create: @create.bind @
        update: @update.bind @
        remove: @remove.bind @
        findWithArray: @findWithArray.bind @
        bindPublisher: @bindPublisher.bind @

module.exports = Db
