# Order Schema

## Struct
```solidity
struct Order {
	/* Exchange address, intended as a versioning mechanism. */
	address exchange;
	/* Order maker address. */
	address maker;
	/* Order taker address, if specified. */
	address taker;
	/* Maker relayer fee of the order, unused for taker order. */
	uint makerRelayerFee;
	/* Taker relayer fee of the order, or maximum taker fee for a taker order. */
	uint takerRelayerFee;
	/* Maker protocol fee of the order, unused for taker order. */
	uint makerProtocolFee;
	/* Taker protocol fee of the order, or maximum taker fee for a taker order. */
	uint takerProtocolFee;
	/* Order fee recipient or zero address for taker order. */
	address feeRecipient;
	/* Fee method (protocol token or split fee). */
	FeeMethod feeMethod;
	/* Side (buy/sell). */
	SaleKindInterface.Side side;
	/* Kind of sale. */
	SaleKindInterface.SaleKind saleKind;
	/* Target. */
	address target;
	/* HowToCall. */
	AuthenticatedProxy.HowToCall howToCall;
	/* Calldata. */
	bytes calldata;
	/* Calldata replacement pattern, or an empty byte array for no replacement. */
	bytes replacementPattern;
	/* Static call target, zero-address for no static call. */
	address staticTarget;
	/* Static call extra data. */
	bytes staticExtradata;
	/* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
	address paymentToken;
	/* Base price of the order (in paymentTokens). */
	uint basePrice;
	/* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
	uint extra;
	/* Listing timestamp. */
	uint listingTime;
	/* Expiration timestamp - 0 for no expiry. */
	uint expirationTime;
	/* Order salt, used to prevent duplicate hashes. */
	uint salt;
}
```

## Field Descriptions
All of the following fields must be present in an order. Some have special sentinel values.
### exchange
Address of the *WyvernExchange* contract. This is a versioning mechanism, ensuring that all signed orders are only valid for a particular deployed version of the Wyvern Protocol on a particular Ethereum chain.
### maker
Order maker (who may be buying or selling the contract call — the maker/taker differentiation is strictly a matter of fees).
### taker
Order taker, if a specific address must take the order, otherwise the zero-address as a sentinel value to indicate that the order can be taken by anyone.
### makerRelayerFee
Maker relayer fee, paid by the maker to the relayer upon execution if this is a maker order.
### takerRelayerFee
Taker relayer fee, paid by the taker to the relayer on execution if this is a maker order, or the maximum such fee if this is a taker order.
### makerProtocolFee
Maker protocol fee, paid to the `protocolFeeRecipient` if this is a maker order.
### takerProtocolFee
Taker protocol fee, paid by the taker to the `protocolFeeRecipient` if this is a maker order, or the maximum such fee if this is a taker order.
### feeRecipient
Address of the relayer who will receive the fee.
### feeMethod
Method of fee calculation (see [this discussion](https://github.com/ProjectWyvern/WDPs/issues/6) for context).
### side
Side (buy or sell). Sell-side orders execute contract calls and receive tokens, buy-side orders purchase contract calls and pay tokens.
### saleKind
Kind of sale, `FixedPrice` or `DutchAuction`.
### target
Target address of call.
### howToCall
Call method, `CALL` or `DELEGATECALL`.
### calldata
Calldata (bytes).
### replacementPattern
Mask specifying which parts of the calldata can be changed, or an empty array for no replacement.
### staticTarget
Target for `STATICCALL`, or zero-address as a sentinel value to indicate no `STATICCALL`.
### staticExtradata
Extra data for `STATICCALL` (bytes).
### paymentToken
Token used to pay for call, or the zero-address as a sentinel value for special-case unwrapped Ether.
### basePrice
Base price of the order, in units of the specified `paymentToken`.
### extra
Extra parameter for price calculation, specifying starting/ending price difference for Dutch auctions. Could be used to specify minimum bid for English auctions in the future should those be implemented.
### listingTime
Order listing Unix timestamp.
### expirationTime
Order expiration Unix timestamp or `0` as a sentinel value for no expiry.
### salt
Order salt to distinguish otherwise-identical orders.
