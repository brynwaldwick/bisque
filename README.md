# Bisque

Self-organizing message routing in ad-hoc peer networks with a decaying “back flow” of rewards for message transport


### Introduction

Blockchains, Edgenet, and other emerging distributed systems operate as networks of peers that pass information about the system state back and forth in the form of messages. These messages can be intended for every peer in the network (in the case of a new bitcoin block being broadcast), or directed to a single peer or group of peers specifically (in the case of a direct message to a user on Edgenet). We seek a way to optimize this messaging that

* Minimizes the transport load on the network by
    * Focusing peers' messaging on the local peers most reliant on their data for syncing
    * Minimizing redundant messages
    * Routing messages efficiently towards a shortest path to an arbitrary peer with limited knowledge of non-local network topology
* Minimizes the time required to propagate state changes across the network or to an intended peer
* (hopefully) Supports a network's native validation rules or cryptographic verification of peers
* (eventually) Functions generally across any peer network by hooking into its native messaging layer, using highly accessible protocols, or providing a standard API so implementing the Bisque Protocol for e.g. a bitcoin node can be done simply with a few calls to the domain-specific client.
    * It could be that the best way to implement this is to just point into each respective system w/ message_id and keep track of all biscuit & messaging optimization data inside Bisque


### About Biscuits

A biscuit is the atomic unit of reward, sent from one peer to another in exchange for successful delivery of a message.

```
Biscuit = {
N #magnitude
message_id #the message that was delivered to cause creation of the biscuit
creator_id #the recipient of the message that created the biscuit
sender_id #the peer that is sending the biscuit
}
```

When a peer receives a message for the first time, it creates a biscuit of magnitude 1 and sends it to the peer who delivered the message. The peer then relays the message downstream in the network (to all its connected peers or to a subsection of peers selected through a biscuit-driven algorithm to be designed).

An "N biscuit" is a partial, divisible piece of a biscuit that is passed further upstream back along a message’s path to higher-order connections. It is a biscuit where N is less than one.

Each peer sets a "reward threshold" n. The peer will reward its first n peers that deliver a given message, both when receiving the message for the first time and when receiving a biscuit or N biscuit back from passing that message downstream to the rest of the network.

When a peer delivers a message to another peer as one of the first n deliverers, it can expect an immediate biscuit from the recieving peer, and (possibly, if the receiving peer has any success forwarding the message downstream) a series of N biscuits flowing back as the message is passed through the network.

When a peer receives an N biscuit in response to a message, it lowers the magnitude by a factor 0 < A < 1 (calculated based on the peer's reward threshold and number of previous deliveries of that message) and sends this smaller N biscuit to the first n peers from which it received that message.


### Weights of Biscuit Back Flow

Consider two approaches for the decay of biscuits as they propagate back through a message's path - simple geometric weights and weights normalized by a peer's reward threshold.


With geometric weights, the magnitude of the N biscuit to be passed to the ith deliverer of a message is given by

`A = N / (2 ^ (i - 1))`

where N is the magnitude of the N biscuit.

For n = 3 the coefficients are
1, 1/2, 1/4

For n = 4 the coefficients are
1, 1/2, 1/4, 1/8

In this way there will always be a biscuit of magnitude 1 passed to every peer that executed a step in the message's most immediate path from peer to peer. This setup also has other desirable properties like

* Similar coefficients regardless of configured reward threshold - easily interpreted without knowledge of peer configuration
* A peer can reconstruct some notion of the transport characteristics of a given biscuit based on its magnitude. e.g. A biscuit with magnitude 1/32 is 5 deliveries removed from a direct first-delivery path.

However this approach has the drawback of not diminishing the reward for the first few deliverers as a peer sets a higher and higher reward threshold. There is no cost to a peer to raising their reward threshold and flooding the network with biscuits to each and every peer to ever deliver a message, regardless of redundancy. The biscuits are a means to optimizing the transport properties of the network, so ideally there would be incentive within the system to not flood biscuits.


With normalized weights, the magnitude of the N biscuit to be passed to the ith deliverer of a message is given by

`A = N * (n - (i - 1)) / (n + (n - 1) + (n - 2) + …)`

where N is the magnitude of the N biscuit, and n is the reward threshold configured by the peer. 

For n = 3 the coefficients are
1/2, 1/3, 1/6

For n = 4 the coefficients are
2/5, 3/10, 1/5, 1/10

With this weighting, regardless of the reward threshold a peer sets, a peer will always pass upstream the same magnitude of N biscuit as it receives (divided up into smaller chunks for each n first deliverers). This conservation of higher order rewards seems elegant and desirable. Additionally in this scheme there is some "cost" in setting a higher reward threshold: A peer with a very high threshold will not be able to reward the first few deliverers as handsomely as a peer with a lower reward threshold. Thus this scheme would appear to incentivize peers to be prudent in the threshold they set so as not to be optimized off from other peers seeking adequate rewards for fast message deliveries.


### Storing biscuit data

Each peer should keep track of

biscuit_deliverers - A dictionary of peer_ids and the biscuits the peer has received from those peers
biscuit_creators - A dictionary of peer_ids and the biscuits this peer has received that were created by those peers


### Operating on biscuit data

The goal of sending and storing biscuits is to measure the topology and transport properties of the peer network and optimize messsage sending. With a notion of higher order connections a peer should be able to direct a message towards a higher-order peer that is not directly connected (by sending the message towards previous biscuit trails with remnants from the target peer), or optimize network use by minimizing unecessary or redundant messages (by ranking peers by the ratio of biscuit magnitude / message sent to each peer to which they connect, and ceasing to send messages to peers that are not lucrative biscuit-wise).

Some functions to explore:

`rankDownstream` - find the peers that are most reliant upon you for early message delivery
    First order: sum of magnitude of biscuits received / number of messages sent to that peer. Note that both the average number of existing deliveries to a peer for a given message AND the effectiveness of that peer in earning biscuits by passing the message downstream will figure into this ratio.

`rankUpstream` - find the peers that have sent you the most useful messages
    First order: magnitude of biscuits sent up stream to peer / number of messages received from peer

`sendOptimizedMessage(R)` - Send or forward a message downstream, only to peers which have a biscuit / message ratio greater than R. A clumsy interpretation of this parameter is "only send to peers where I am on average the < nth person to send them any given message", though again note that a peers effectiveness in earning biscuits for passing a message downstream will figure into this ratio.

`sendDirectedMessage` - Direct a message towards a given peer
    First order: if you're connected to this peer, send the message to that peer. Otherwise, examine biscuit data to find any trails that have lead to that peer in the past (N biscuits you have with creator_id equal to this peer_id).
	Second order: ask connected peers for a promising biscuit trail. They could then recursively ask for a promising trail down to a certain threshold if they cannot find one.

`requestTrail` - Recursively request any promising biscuit trails towards a peer id from all connected peers. Since this is sending another message perhaps it is best to simply flood the message to all connected peers in this case.


### UI for measuring & testing in a simple webapp

For each peer, keep track of...

The list of peers they know about... and for each of those
Are they connected
List of messages sent
List of messages received
List of biscuits received
Biscuit/message score (ranked)
Downstream peers (ranked)


### Potential issues

* Is it possible to optimize enough that it is worth sending a bunch of f. biscuits for each message step?
    * Briefly, it seems like we must be able to do better than N^2 message flooding in the base case. The number of biscuits sent per successful message delivery is roughly `n_avg^p_avg`, where n_avg is the average reward threshold set by the network, and p_avg is the average path length required to propagate a message to its full set of intended destinations.
* Forged biscuits (?)
* Tampered messages (beyond the scope of initial research)
* Is it possible to attack this and stop some peers from getting messages altogether by tricking other nodes into optimizing them off the network?
