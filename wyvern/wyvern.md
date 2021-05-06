# Wyvern Protocol

## Overview

Wyvern is a protocol for the decentralized exchange of nonfungible digital assets. Like decentralized fungible token exchange protocols, [Etherdelta](https://etherdelta.com) and [0x](https://0xproject.com), Wyvern uses a hybrid model: signed orders are transmitted and stored off-chain, while all state transitions are settled on-chain, meaning that protocol users need not trust any counterparty with custody of their assets. Unlike prior protocols, Wyvern is representation-agnostic: the protocol uses a proxy account system to abstract over the space of Ethereum transactions, allowing arbitrary state transitions to be bought and sold without the deployment of any additional smart contracts. Wyvern supports buy- and sell-side orders, fixed price and Dutch auction pricing, and asset criteria specification — orders may be placed for specific assets, or for any assets with specific properties.

## Contract Architecture
```
.
├── exchange
│   ├── Exchange.sol
│   ├── ExchangeCore.sol
│   └── SaleKindInterface.sol
└── registry
    ├── AuthenticatedProxy.sol
    ├── OwnableDelegateProxy.sol
    ├── ProxyRegistry.sol
    └── TokenTransferProxy.sol
```

### Registry

The registry contracts proxy all user authentication. Protocol users transfer assets to a personal proxy contract and approve token transfers through a token proxy contract. 

### Exchange

The exchange contracts implement the core protocol logic. 

## [Order Schema](./order-schema.md)

## Market Architecture

```
+----------------------------------+
|            contract              |
+----------------^-----------------+
                 |
+----------------+-----------------+
|    backend(orderbook server)     |
+----------------^-----------------+
                 |
+----------------+-----------------+
|         frontend/JS SDK          |
+----------------------------------+
```

## Orderbook Server / Relayer
* [Example](https://github.com/ProjectWyvern/example-orderbook-server) (No maintenance for three years)  
An orderbook is just a list of orders that an exchange uses to record the interest of buyers and sellers. On OpenSea, most actions are off-chain, meaning they generate orders that are stored in the orderbook and can be fulfilled by a matching order from another user.

## Integration
* [wyvern-js](https://github.com/ProjectWyvern/wyvern-js) (No maintenance for three years) 
* [wyvern-schemas](https://github.com/ProjectWyvern/wyvern-schemas.git)

## OpenSea
* [OpenSea API](https://docs.opensea.io/reference#api-overview): Backend orderbooks.
* [opensea-js](https://github.com/ProjectOpenSea/opensea-js): Interact with OpenSea API. 
* [opensea-whitelabel](https://github.com/ProjectOpenSea/opensea-whitelabel): Embed a fully functional OpenSea marketplace on your own website.

### Which actions require gas fees on OpenSea?

#### One-Time Fees
* Account Registration fees (user proxy)
* ERC20 approval

#### Transaction Fees
- Accepting an offer
- Transfering (or Gifting) an NFT to someone
- Buying a NFT
- Canceling a listed NFT
- Canceling a Bid
- Converting WETH back to ETH, and vice versa.

#### Gas-Free Actions
- Minting a new NFT aka [Lazy Minting](https://opensea.io/blog/announcements/introducing-the-collection-manager/)
- Creating a collection
- Listing an NFT as fixed price
- Listing an NFT as auction
- Reducing the price of an NFT you've listed 

### [Gas-Free](https://medium.com/opensea/introducing-ebay-style-auctions-for-crypto-collectibles-47ba856155de)
`Relayer` could auto-match the highest bid with the auction, so neither sellers nor buyers have to pay gas.
1. Sellers create auctions by creating and signing an off-chain sell order, which `Relayer` stores off-chain with the `Orderbook Server`. 
2. Buyers create buy orders in the same way, which also only requires signatures. To bid on an item for sale in an ERC-2O token.
3. When the sell order expires, `Orderbook Server` look for the highest buy order that’s at least the minimum amount specified by the seller, and pays the gas to match the two together. 

### Tech View
```
+-------------+                                                           +-------------+
|  frontend   |                 (0)registry proxy                         |   contract  |
|             +----------------------------------------------------------->             |
|             +----------------------------------------------------------->             |
|             |                   cancel order                            |             |
|             |                                                           |             |
|             |                       +--------------+                    |             |
|             |                       |              |                    |             |
|   sellers   |      encode sell      |              |                    |             |
|             |      create order     |   orderbook  |                    |             |
|             +----------------------->    server    |                    |             |
|             |      sign order       |              |                    |             |
|             |    (1)post order      |              |                    |             |
|             |                       |              |                    |             |
+-------------+                       |              |   (4)atomic match  |             |
|             |                       |    relayer   +-------------------->             |
|             |     (2)fetch order    |              |                    |             |
|             <-----------------------+              |                    |             |
|             |                       |              |                    |             |
|             |      encode buy       |              |                    |             |
|             |      create order     |              |                    |             |
|   buyers    +----------------------->              |                    |             |
|             |      sign order       |              |                    |             |
|             |     (3)post order     |              |                    |             |
|             |                       +--------------+                    |             |
|             |                                                           |             |
|             |                     cancel order                          |             |
|             +----------------------------------------------------------->             |
|             +----------------------------------------------------------->             |
|             |                   (0)registry proxy                       |             |
+-------------+                                                           +-------------+
```
## Inconclusion
1. Leverage existing orderooks.
	* Advantages:
		- OpenSea [Ecosystem](https://docs.opensea.io/docs/opensea-presale) (OpenSea API, JS SDK, whitelabel, Referral / affiliate system)
		- Less Work.
	* Disadvantages:
		- Only Support Atlantis. Matic.
2. Deploy your own.
	* Advantages:
		- Supprot all lands.
		- More control.
	* Disadvantages:
		- More Work to maintain orderbook.

## Terminology
* Maker: make liquidity
* Taker: take liquidity
