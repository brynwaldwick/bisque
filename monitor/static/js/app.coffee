somata = require 'somata-socketio-client'
React = require 'react'
ReactDOM = require 'react-dom'
{Router, Link, Route, IndexRoute, browserHistory, hashHistory} = require 'react-router'

DataService = somata.remote.bind null, 'bisque:data'
Dispatcher = {

    graphQL: (query, cb) ->
        DataService 'query', query, {}, cb
}

# subscribe_updates$ = somata.subscribe$.bind null, 'bisque:updates'
# peerChildren$ = (peer_id, child_key) ->
#     subscribe_updates$ "peers:#{peer_id}:child_key"

App = React.createClass

    render: ->
        <div className='app'>
            <div className='nav'>
                <div>
                    <Link to='/'>
                        <h1>bisque monitor</h1>
                    </Link>
                </div>
            </div>
            {@props.children}
        </div>

PeerSummary = ({peer}) ->
    console.log peer
    <div className='summary'>
        <div className='field id'>
            {peer.id}
        </div>
        <div className='field username'>
            {peer.username}
        </div>
    </div>

Peers = React.createClass
    subscribe$: somata.subscribe$.bind null, 'bisque:data'

    getInitialState: ->
        peers: []

    componentDidMount: ->
        Dispatcher.graphQL '''
            {peers
                {id,username,
                    connections{
                        to_peer{id,username}
                    }
                    messages{
                        id,kind,body,from,from_peer{id, username}
                    }
                    biscuits{
                        id,magnitude,message_id,from_peer_id,source_message_id
                    }
                }
            }
        ''', (err, {peers}) =>
            @setState {peers}, =>
                ['messages', 'biscuits', 'connections'].map (k) =>
                    @subscribe$("#{k}:created").onValue (event) =>
                        console.log "new #{k}", event
                        @insertItem k, event.item

    insertItem: (key, item) ->
        peers = @state.peers
        console.log item.to_peer_id
        console.log key
        console.log peers
        if key == 'connections'
            peer_to_update = peers.filter((p) -> Number(p.id) == item.from_peer_id)[0]
        else
            peer_to_update = peers.filter((p) -> Number(p.id) == item.to_peer_id)[0]
        console.log peer_to_update
        peer_to_update?[key]?.push item
        @setState {peers}

    render: ->
        <div className='peers-page content' >
            {@state.peers.map @renderPeer}
        </div>

    renderPeer: (peer, i) ->
        <div key=i className='peer'>
            <PeerSummary peer=peer />
            <div className='connections'>
                <h5>Connections</h5>
                {peer.connections?.map @renderConnection}
            </div>
            <div className='connections'>
                <h5>Messages</h5>
                {peer.messages?.map @renderMessage}
            </div>
            <div className='biscuits'>
                <h5>Biscuits</h5>
                {peer.biscuits?.map @renderBiscuit}
            </div>
        </div>

    renderConnection: (connection, i) ->
        <div key=i className='connection'>
            <PeerSummary peer=connection.to_peer />
        </div>

    renderBiscuit: (b, i) ->
        <div key=i className='biscuit'>
            <div className='summary'><strong>{b.magnitude.toFixed(2)}</strong><span> from {b.from_peer_id} for message {b.source_message_id} </span></div>
        </div>

    renderMessage: (message, i) ->
        console.log message.kind
        <div key=i className='message'>
             <div>[{message.kind} id:{message.id}] from {message.from}</div>
        </div>

routes =
    <Route path="/" component=App >
        <IndexRoute component=Peers />
    </Route>

ReactDOM.render <Router routes={routes} history={hashHistory} />, document.getElementById 'app'
