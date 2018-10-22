pragma solidity ^0.4.23;

import "./interfaces/IMysteriousTreasure.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "@evolutionland/common/contracts/interfaces/ERC223.sol";
import "@evolutionland/common/contracts/PausableDSAuth.sol";
import "@evolutionland/land/contracts/interfaces/ILandBase.sol";
import "./AuctionSettingIds.sol";
import "./interfaces/IBancorExchange.sol";

contract ClockAuction is PausableDSAuth, AuctionSettingIds {
    using SafeMath for *;
    event AuctionCreated(uint256 tokenId, address seller, uint256 startingPriceInToken, uint256 endingPriceInToken, uint256 duration, address token);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    // new bid event
    event NewBid(uint256 indexed tokenId, address lastBidder, address lastReferer, uint256 lastRecord, address tokenAddress, uint256 bidStartAt, uint256 returnToLastBidder);

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in token) at beginning of auction
        uint128 startingPriceInToken;
        // Price (in token) at end of auction
        uint128 endingPriceInToken;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
        // it saves gas in this order
        // highest offered price (in RING)
        uint128 lastRecord;
        // bid the auction through which token
        address token;
        // bidder who offer the highest price
        address lastBidder;
        // latestBidder's bidTime in timestamp
        uint256 lastBidStartAt;
        // lastBidder's referer
        address lastReferer;
    }

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    // Map from token ID to their corresponding auction.
    mapping(uint256 => Auction) public tokenIdToAuction;

    /*
    *  Modifiers
    */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    modifier isHuman() {
        require(msg.sender == tx.origin, "robot is not permitted");
        _;
    }

        // Modifiers to check that inputs can be safely stored with a certain
    // number of bits. We use constants and multiple modifiers to save gas.
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

    modifier isOnAuction(uint256 _tokenId) {
        require(tokenIdToAuction[_tokenId].startedAt > 0);
        _;
    }

    ///////////////////////
    // Constructor
    ///////////////////////
    constructor() public {
        // initializeContract
    }

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    ///  bidWaitingMinutes - biggest waiting time from a bid's starting to ending(in minutes)
    function initializeContract(
        ISettingsRegistry _registry) public singletonLockCall {

        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        registry = _registry;
    }

    /// @dev DON'T give me your money.
    function() external {}

    ///////////////////////
    // Auction Create and Cancel
    ///////////////////////

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _startAt,
        address _token) // with any token
    public auth
    canBeStoredWith64Bits(_startAt) {
        _createAuction(msg.sender, _tokenId, _startingPriceInToken, _endingPriceInToken, _duration, _startAt, msg.sender, _token);
    }

    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId) public isOnAuction(_tokenId)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];

        address seller = auction.seller;
        require((msg.sender == seller && !paused) || msg.sender == owner);

        // once someone has bidden for this auction, no one has the right to cancel it.
        require(auction.lastBidder == 0x0);

        delete tokenIdToAuction[_tokenId];

        ERC721Basic(registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)).safeTransferFrom(this, seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    //@dev only NFT contract can invoke this
    //@param _from - owner of _tokenId
    function receiveApproval(
        address _from,
        uint256 _tokenId,
        bytes //_extraData
    )
    public
    whenNotPaused
    {
        if (msg.sender == registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)) {
            uint256 startingPriceInRING;
            uint256 endingPriceInRING;
            uint256 duration;
            address seller;

            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize)
                startingPriceInRING := mload(add(ptr, 132))
                endingPriceInRING := mload(add(ptr, 164))
                duration := mload(add(ptr, 196))
                seller := mload(add(ptr, 228))
            }

            // TODO: add parameter _token
            _createAuction(_from, _tokenId, startingPriceInRING, endingPriceInRING, duration, now, seller, registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN));
        }

    }

    ///////////////////////
    // Bid With Auction
    ///////////////////////

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    /// @dev bid with eth(in wei). Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function bidWithETH(uint256 _tokenId, address _referer)
    public
    payable
    whenNotPaused
    isHuman
    isOnAuction(_tokenId)
    returns (uint256)
    {
        require(msg.value > 0);
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        // can only bid the auction that allows ring
        require(auction.token == registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN));

        // Check that the incoming bid is higher than the current
        // price
        uint256 priceInRING = getCurrentPriceInToken(_tokenId);
        // assure msg.value larger than current price in ring
        // priceInRING represents minimum return
        // if return is smaller than priceInRING
        // it will be reverted in bancorprotocol
        // so dont worry
        IBancorExchange bancorExchange = IBancorExchange(registry.addressOf(AuctionSettingIds.CONTRACT_BANCOR_EXCHANGE));
        uint errorSpace = registry.uintOf(AuctionSettingIds.UINT_EXCHANGE_ERROR_SPACE);
        (uint256 ringFromETH, ) = bancorExchange.buyRINGInMinRequiedETH.value(msg.value)(priceInRING, msg.sender, errorSpace);

        // double check
        uint refund = ringFromETH.sub(priceInRING);
        if (refund > 0) {
            // if there is surplus RING
            // then give it back to the msg.sender
            ERC20(registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN)).transfer(msg.sender, refund);
        }

        uint bidMoment;
        uint returnToLastBidder;
        (bidMoment, returnToLastBidder) = _bidProcess(msg.sender, auction, priceInRING, _referer);

        // Tell the world!
        // 0x0 refers to ETH
        // NOTE: priceInRING, not priceInETH
        emit NewBid(_tokenId, msg.sender, _referer, priceInRING, 0x0, bidMoment, returnToLastBidder);

        return priceInRING;
    }

    // @dev bid with RING. Computes the price and transfers winnings.
    function _bidWithToken(address _from, uint256 _tokenId, uint256 _valueInToken, address _referer) internal returns (uint256){
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Check that the incoming bid is higher than the current price
        uint priceInToken = getCurrentPriceInToken(_tokenId);
        require(_valueInToken >= priceInToken,
            "your offer is lower than the current price, try again with a higher one.");
        uint refund = _valueInToken - priceInToken;

        if (refund > 0) {
            ERC20(auction.token).transfer(_from, refund);
        }

        uint bidMoment;
        uint returnToLastBidder;
        (bidMoment, returnToLastBidder) = _bidProcess(_from, auction, priceInToken, _referer);

        // Tell the world!
        emit NewBid(_tokenId, _from, _referer, priceInToken, auction.token, bidMoment, returnToLastBidder);

        return priceInToken;
    }

    // here to handle bid for LAND(NFT) using RING
    // @dev bidder must use RING.transfer(address(this), _valueInRING, bytes32(_tokenId)
    // to invoke this function
    // @param _data - need to be generated from (tokenId + referer)

    function tokenFallback(address _from, uint256 _valueInToken, bytes _data) public whenNotPaused {
        uint tokenId;
        address referer;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            tokenId := mload(add(ptr, 132))
            referer := mload(add(ptr, 164))
        }

        // safer for users
        require (msg.sender == tokenIdToAuction[tokenId].token);
        require(tokenIdToAuction[tokenId].startedAt > 0);

        _bidWithToken(_from, tokenId, _valueInToken, referer);
    }

    // TODO: advice: offer some reward for the person who claimed
    // @dev claim _tokenId for auction's lastBidder
    function claimLandAsset(uint _tokenId) public isHuman isOnAuction(_tokenId) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // at least bidWaitingTime after last bidder's bid moment,
        // and no one else has bidden during this bidWaitingTime,
        // then any one can claim this token(land) for lastBidder.
        require(auction.lastBidder != 0x0 && now >= auction.lastBidStartAt + registry.uintOf(AuctionSettingIds.UINT_AUCTION_BID_WAITING_TIME),
            "this auction has not finished yet, try again later");

        IMysteriousTreasure mysteriousTreasure = IMysteriousTreasure(registry.addressOf(AuctionSettingIds.CONTRACT_MYSTERIOUS_TREASURE));
        mysteriousTreasure.unbox(_tokenId);

        address lastBidder = auction.lastBidder;
        uint lastRecord = auction.lastRecord;

        delete tokenIdToAuction[_tokenId];

        ERC721Basic(registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)).safeTransferFrom(this, lastBidder, _tokenId);

        emit AuctionSuccessful(_tokenId, lastRecord, lastBidder);
    }

    function _firstPartBid(uint _auctionCut, uint _refererCut, address _pool, address _buyer, Auction storage _auction, uint _priceInToken, address _referer) internal returns (uint, uint){
        require(now >= uint256(_auction.startedAt));
        //  Calculate the auctioneer's cut.
        // (NOTE: computeCut() is guaranteed to return a
        //  value <= price, so this subtraction can't go negative.)
        // TODO: token to the seller
        uint256 ownerCutAmount = computeCut(_priceInToken, _auctionCut);

        // transfer to the seller
        ERC223(_auction.token).transfer(_auction.seller, (_priceInToken - ownerCutAmount), toBytes(_buyer));

        if (_referer != 0x0) {
            uint refererBounty = computeCut(ownerCutAmount, _refererCut);
            ERC20(_auction.token).transfer(_referer, refererBounty);
            ERC223(_auction.token).transfer(_pool, (ownerCutAmount - refererBounty), toBytes(_buyer));
        } else {
            ERC223(_auction.token).transfer(_pool, ownerCutAmount, toBytes(_buyer));
        }

        // modify bid-related member variables
        _auction.lastBidder = _buyer;
        _auction.lastRecord = uint128(_priceInToken);
        _auction.lastBidStartAt = now;
        _auction.lastReferer = _referer;

        return (_auction.lastBidStartAt, 0);
    }


    function _secondPartBid(uint _auctionCut, uint _refererCut, address _pool, address _buyer, Auction storage _auction, uint _priceInToken, address _referer) internal returns (uint, uint){
        // TODO: repair bug of first bid's time limitation
        // if this the first bid, there is no time limitation
        require(now <= _auction.lastBidStartAt + registry.uintOf(AuctionSettingIds.UINT_AUCTION_BID_WAITING_TIME), "It's too late.");

        // _priceInToken that is larger than lastRecord
        // was assured in _currentPriceInRING(_auction)
        // here double check
        // 1.1*price + bounty - (price + bounty) = 0.1 * price
        uint surplus = _priceInToken.sub(uint256(_auction.lastRecord));
        uint poolCutAmount = computeCut(surplus, _auctionCut);
        uint extractFromGap = surplus - poolCutAmount;
        uint realReturnForEach = extractFromGap / 2;

        // here use transfer(address,uint256) for safety
        ERC20(_auction.token).transfer(_auction.seller, realReturnForEach);
        ERC20(_auction.token).transfer(_auction.lastBidder, (realReturnForEach + uint256(_auction.lastRecord)));

        if (_referer != 0x0) {
            uint refererBounty = computeCut(poolCutAmount, _refererCut);
            ERC20(_auction.token).transfer(_referer, refererBounty);
            ERC223(_auction.token).transfer(_pool, (poolCutAmount - refererBounty), toBytes(_buyer));
        }

        // modify bid-related member variables
        _auction.lastBidder = _buyer;
        _auction.lastRecord = uint128(_priceInToken);
        _auction.lastBidStartAt = now;
        _auction.lastReferer = _referer;

        return (_auction.lastBidStartAt, (realReturnForEach + uint256(_auction.lastRecord)));
    }

    // TODO: add _token to compatible backwards with ring and eth
    function _bidProcess(address _buyer, Auction storage _auction, uint _priceInToken, address _referer)
    internal
    canBeStoredWith128Bits(_priceInToken)
    returns (uint256, uint256){

        uint auctionCut = registry.uintOf(AuctionSettingIds.UINT_AUCTION_CUT);
        uint256 refererCut = registry.uintOf(AuctionSettingIds.UINT_REFERER_CUT);
        address revenuePool = registry.addressOf(AuctionSettingIds.CONTRACT_REVENUE_POOL);

        // uint256 refererBounty;

        // the first bid
        if (_auction.lastBidder == 0x0 && _priceInToken > 0) {

            return _firstPartBid(auctionCut, refererCut, revenuePool, _buyer, _auction, _priceInToken, _referer);
        }

        // TODO: the math calculation needs further check
        //  not the first bid
        if (_auction.lastRecord > 0 && _auction.lastBidder != 0x0) {

            return _secondPartBid(auctionCut, refererCut, revenuePool, _buyer, _auction, _priceInToken, _referer);
        }

    }


    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function computeCut(uint256 _price, uint256 _cut) public pure returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * _cut / 10000;
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
    public
    view
    returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt,
        address token,
        uint128 lastRecord,
        address lastBidder,
        uint256 lastBidStartAt,
        address lastReferer
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return (
            auction.seller,
            auction.startingPriceInToken,
            auction.endingPriceInToken,
            auction.duration,
            auction.startedAt,
            auction.token,
            auction.lastRecord,
            auction.lastBidder,
            auction.lastBidStartAt,
            auction.lastReferer
        );
    }

    /// @dev Returns the current price of an auction.
    /// Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPriceInToken(uint256 _tokenId)
    public
    view
    returns (uint256)
    {
        uint256 secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn't ever go backwards).
        if (now > tokenIdToAuction[_tokenId].startedAt) {
            secondsPassed = now - tokenIdToAuction[_tokenId].startedAt;
        }
        // if no one has bidden for _auction, compute the price as below.
        if (tokenIdToAuction[_tokenId].lastRecord == 0) {
            return _computeCurrentPriceInToken(
                tokenIdToAuction[_tokenId].startingPriceInToken,
                tokenIdToAuction[_tokenId].endingPriceInToken,
                tokenIdToAuction[_tokenId].duration,
                secondsPassed
            );
        } else {
            // compatible with first bid
            // as long as price_offered_by_buyer >= 1.1 * currentPice,
            // this buyer will be the lastBidder
            // 1.1 * (lastRecord)
            return (11 * (uint256(tokenIdToAuction[_tokenId].lastRecord)) / 10);
        }
    }

    // to apply for the safeTransferFrom
    function onERC721Received(
        address, //_operator,
        address, //_from,
        uint256, // _tokenId,
        bytes //_data
    )
    public
    returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    // get auction's price of last bidder offered
    // @dev return price of _auction (in RING)
    function getLastRecord(uint _tokenId) public view returns (uint256) {
        return tokenIdToAuction[_tokenId].lastRecord;
    }

    function getLastBidder(uint _tokenId) public view returns (address) {
        return tokenIdToAuction[_tokenId].lastBidder;
    }

    function getLastBidStartAt(uint _tokenId) public view returns (uint256) {
        return tokenIdToAuction[_tokenId].lastBidStartAt;
    }

    // @dev if someone new wants to bid, the lowest price he/she need to afford
    function computeNextBidRecord(uint _tokenId) public view returns (uint256) {
        return getCurrentPriceInToken(_tokenId);
    }

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    //  NOTE: change _startingPrice and _endingPrice in from wei to ring for user-friendly reason
    /// @param _startingPriceInToken - Price of item (in token) at beginning of auction.
    /// @param _endingPriceInToken - Price of item (in token) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    /// @param _seller - Seller, if not the message sender
    function _createAuction(
        address _from,
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _startAt,
        address _seller,
        address _token
    )
    internal
    whenNotPaused
    canBeStoredWith128Bits(_startingPriceInToken)
    canBeStoredWith128Bits(_endingPriceInToken)
    canBeStoredWith64Bits(_duration)
    canBeStoredWith64Bits(_startAt)
    {
        require(_startingPriceInToken <= (1000000000 ether) && _endingPriceInToken <= (1000000000 ether));
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_duration >= 1 minutes, "duration must be at least 1 minutes");
        require(_duration <= 1000 days);

        // escrow
        ERC721Basic(registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)).safeTransferFrom(_from, this, _tokenId);

        tokenIdToAuction[_tokenId] = Auction({
            seller: _seller,
            startingPriceInToken: uint128(_startingPriceInToken),
            endingPriceInToken: uint128(_endingPriceInToken),
            duration: uint64(_duration),
            startedAt: uint64(_startAt),
            lastRecord: 0,
            token: _token,
            // which refer to lastRecord, lastBidder, lastBidStartAt,lastReferer
            // all set to zero when initialized
            lastBidder: address(0),
            lastBidStartAt: 0,
            lastReferer: address(0)
        });

        emit AuctionCreated(_tokenId, _seller, _startingPriceInToken, _endingPriceInToken, _duration, _token);
    }

    /// @dev Computes the current price of an auction. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function public and turn on
    ///  `Current price computation` test suite.
    function _computeCurrentPriceInToken(
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _secondsPassed
    )
    internal
    pure
    returns (uint256)
    {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (_secondsPassed >= _duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPriceInToken;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceInTokenChange = int256(_endingPriceInToken) - int256(_startingPriceInToken);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceInTokenChange = totalPriceInTokenChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPriceInToken = int256(_startingPriceInToken) + currentPriceInTokenChange;

            return uint256(currentPriceInToken);
        }
    }


    function toBytes(address x) public pure returns (bytes b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
}
