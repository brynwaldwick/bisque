config = require './config'
polar = require 'somata-socketio'
somata = require 'somata'

client = new somata.Client()
DataService = client.remote.bind client, 'tryna:data'

app = polar {port: 5821}, middleware: []

app.get '/', (req, res) ->
    res.render 'app'

app.start()