somata = require 'somata'
schema = require './schema'
graphql = require './graphql'

LocalDb = require './local-db'

db = new LocalDb schema
db = db.bindAll()
db.query = graphql.query.bind null, db

service = new somata.Service 'bisque:data', db

db.bindPublisher service
