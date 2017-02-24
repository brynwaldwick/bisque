util = require 'util'

exports.randomChoice = (l) ->
    l[Math.floor Math.random() * l.length]

exports.descend = descend = (o, ks) ->
    if typeof ks == 'string'
        ks = ks.split('.')
    k = ks.shift()
    if k?
        descend o[k], ks
    else
        return o

exports.objectMatcher = (query) -> (item) ->
    matches = true
    for key, value of query
        if descend(item, key) != value
            matches = false
    return matches

# Generate a random alphanumeric string
exports.randomString = (len=8) ->
    s = ''
    while s.length < len
        s += Math.random().toString(36).slice(2, len-s.length+2)
    return s

exports.mapObj = (f, o) ->
    o_ = []
    for k, v of o
        o_[k] = f v
    o_

exports.inspect = (t, o) ->
    if !o?
        o = t
        t = null
    s = util.inspect o, colors: true, depth: null
    if t?
        console.log "[#{t}]", s
    else
        console.log s

exports.inspector = (t) -> (o) -> exports.inspect t, o

exports.isNullObject = (object) ->
    return !object? || Object.keys(object)?.length == 0

exports.hasNullKeys = (object) ->
    has_null_keys = false
    Object.keys(object).map (k) ->
        if !object[k]?
            has_null_keys = true
    return has_null_keys
