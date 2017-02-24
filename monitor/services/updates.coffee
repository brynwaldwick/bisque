somata = require 'somata'
client = new somata.Client()

service = new somata.Service 'bisque:updates', {

}

client.subscribe 'bisque:data', 'messages:created', (event) ->
    console.log event.item
    service.publish "peers:#{event.item.to_peer_id}:messages", event.item

client.subscribe 'bisque:data', 'biscuits:created', (event) ->
    console.log event.item
    service.publish "peers:#{event.item.to_peer_id}:biscuits", event.item
