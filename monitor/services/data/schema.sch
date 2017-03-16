Peer
    username String
    connections Connection < from_peer_id
    messages Message < to_peer_id
    biscuits Biscuit < to_peer_id

Connection
    from_peer Peer > from_peer_id
    to_peer Peer > to_peer_id

Message
    kind String
    body String
    from_peer Peer > from
    to_peer Peer > to_peer_id
    target_peer Peer > target

Biscuit
    magnitude Float
    message Message > message_id
    from_peer Peer > from_peer_id
    to_peer Peer > to_peer_id
    source_message Message > source_message_id
