somata = require 'somata'
{parseSchema, buildDb, graphql} = require 'data-service'
fs = require 'fs'

schema = parseSchema fs.readFileSync('schema.sch', 'utf8').trim()
db_type = process.argv[2]

service = new somata.Service 'bisque:data', {}

attachTrigger = (type, key, fn) ->
    type_entry = schema.filter((s) -> s.name == type)[0]
    type_entry[key] = fn

triggers = {}

Object.keys(triggers).map (type_key) ->
    Object.keys(triggers[type_key]).map (trigger_key) ->
        attachTrigger type_key, trigger_key, triggers[type_key][trigger_key]

schema.id_key = 'id'
db = buildDb db_type, schema, service, {db_name: 'bisque'}
db = db.bindAll()

graphql = graphql(schema)
db.query = graphql.query.bind null, db

service.methods = db
