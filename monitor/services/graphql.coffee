graphql = require 'graphql'
somata = require 'somata'
{inspect} = require './helpers'
GraphQLJSON = require 'graphql-type-json'


object_schema = """
    Peer
        id String
        username String
        connections Connection < from_peer_id
        messages Message < to_peer_id
        biscuits Biscuit < to_peer_id

    Connection
        id String
        from_peer Peer > from_peer_id
        to_peer Peer > to_peer_id

    Message
        id String
        body String
        kind String
        network_id String

        from_peer Peer > from
        to_peer Peer > to_peer_id
        target_peer Peer > target_peer_id
        biscuits Biscuit < message_id

    Biscuit
        id String
        magnitude Float
        message Message > message_id

        creator Peer > creator_id
        source_message Message > source_message_id

        from_peer Peer > from_peer_id
        to_peer Peer > to_peer_id
"""

# Parsing the Schema

tokenizeSchema = (object_schema) ->
    object_schema.split('\n\n').map tokenizeSection

tokenizeSection = (section) ->
    section = section.split('\n')
    key = section.shift()
    lines = section.map (line) ->
        line.trim().split(' ')
    [key, lines]

parseSection = ([key, lines]) ->
    [name, collection] = key.split(' ')
    singular = name.toLowerCase()
    if !collection?
        collection = singular + 's'
    {
        name, singular, collection
        fields: lines.map parseLine
    }

parseLine = (line) ->
    if line.length == 2
        [name, type] = line
        {name, type}
    else
        [name, type, dir, key] = line
        {name, type, dir, key}

tokenized = tokenizeSchema object_schema
parsed = tokenized.map parseSection

# Building the Schema

parsed_types = {} # For easy reference to original parsed types
parsed.map (parsed_type) ->
    parsed_types[parsed_type.name] = parsed_type

builtin_types =
    String: graphql.GraphQLString
    Int: graphql.GraphQLInt
    Float: graphql.GraphQLFloat
    JSON: GraphQLJSON

custom_types = {}
input_types = {}

parsed.map (parsed_type) ->
    custom_types[parsed_type.name] = new graphql.GraphQLObjectType
        name: parsed_type.name
        fields: ->
            fieldsForParsedFields parsed_type.fields

parsed.map (parsed_type) ->
    input_types[parsed_type.name + 'Input'] = new graphql.GraphQLInputObjectType
        name: parsed_type.name + 'Input'
        fields: ->
            inputFieldsForParsedFields parsed_type.fields

fieldsForParsedFields = (parsed_fields) ->
    fields = {id: type: graphql.GraphQLID} # Everything has an ID by default

    parsed_fields.map (parsed_field) ->

        # Reference to a builtin type
        if builtin_type = builtin_types[parsed_field.type]
            fields[parsed_field.name] = type: builtin_type

        else
            # Add a regular ID field for get attachments, e.g. interaction.user_id
            if parsed_field.dir == '>'
                fields[parsed_field.key] = type: graphql.GraphQLID

            # Create the full type and resolver
            fields[parsed_field.name] = customFieldForParsedField parsed_field

    return fields

customFieldForParsedField = (parsed_field) ->
    {collection} = parsed_types[parsed_field.type]
    Type = custom_types[parsed_field.type]
    InputType = input_types[parsed_field.type + 'Input']

    # Get attachments (>) look for an external object by id from self[key]
    if parsed_field.dir == '>'
        resolve = (self, args, context) ->
            query = {id: self[parsed_field.key]}
            if args.query?
                Object.assign query, args.query
            return getType context, collection, query

    # Find attachments (<) look for other objects matching obj[key] = self.id
    else if parsed_field.dir == '<'
        Type = new graphql.GraphQLList Type # Will return a list
        resolve = (self, args, context) ->
            query = {}
            query[parsed_field.key] = self.id
            if args.query?
                Object.assign query, args.query
            return findType context, collection, query

    return {
        type: Type
        args:
            query: type: InputType
        resolve
    }

inputFieldsForParsedFields = (parsed_fields) ->
    fields = {}
    parsed_fields.map (parsed_field) ->
        if builtin_type = builtin_types[parsed_field.type]
            fields[parsed_field.name] = type: builtin_type
        else if parsed_field.dir == '>'
            fields[parsed_field.key] = type: graphql.GraphQLID
    return fields

query_fields = {}
mutation_fields = {}

parsed.map (parsed_type) ->
    {singular, collection} = parsed_type
    Type = custom_types[parsed_type.name]
    InputType = input_types[parsed_type.name + 'Input']

    query_fields[singular] =
        type: Type
        args:
            id: type: graphql.GraphQLID
        resolve: (_, {id}, context) ->
            getType(context, collection, {id})

    query_fields[collection] =
        type: new graphql.GraphQLList Type
        args:
            query: type: InputType
        resolve: (_, {query}, context) ->
            findType(context, collection, query)

    mutation_fields['create_' + singular] =
        type: Type
        args:
            create: type: InputType
        resolve: (_, {id, create}, context) ->
            createType(context, collection, create)

    mutation_fields['update_' + singular] =
        type: Type
        args:
            id: type: graphql.GraphQLID
            update: type: InputType
        resolve: (_, {id, update}, context) ->
            updateType(context, collection, id, update)

QueryType = new graphql.GraphQLObjectType
    name: 'Query'
    fields: query_fields

MutationType = new graphql.GraphQLObjectType
    name: 'Mutation'
    fields: mutation_fields

graphql_schema = new graphql.GraphQLSchema
    query: QueryType
    mutation: MutationType

# Resolvers

## Promise helpers

promiseFromAsync = (fn) -> (args...) ->
    new Promise (resolve, reject) ->
        fn args..., (err, response) ->
            if response?
                resolve response
            else
                reject err

p = (fn, args...) -> promiseFromAsync(fn)(args...)

## Main CRUD methods, bound to DB passed in root context

getType = ({db}, collection, query) ->
    console.log '[getType]', collection, query
    p db.get, collection, query

findType = ({db}, collection, query) ->
    console.log '[findType]', collection, query
    p db.find, collection, query

createType = ({db}, collection, new_item) ->
    console.log '[createType]', collection, new_item
    p db.create, collection, new_item

updateType = ({db}, collection, id, item_update) ->
    console.log '[updateType]', collection, item_update
    item = getType collection, {id}
    p db.update, collection, item_update

# Queries

runQuery = (db, query, variables) ->
    graphql_root = {}
    graphql_context = {db}
    graphql.graphql(graphql_schema, query, graphql_root, graphql_context, variables)

module.exports =
    query: (db, query, variables, cb) ->
        runQuery(db, query, variables)
            .then ({errors, data}) ->
                console.log errors, data
                cb errors, data

