pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./ITokenVendor.sol";


/// @title Auction Core
/// @dev Contains models, variables, and internal methods for the auction.
contract ClockAuctionBase {
    using SafeMath for *;
    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in RING) at beginning of auction
        uint128 startingPriceInRING;
        // Price (in RING) at end of auction
        uint128 endingPriceInRING;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;

        // TODO: add attributes related to bid
        // it saves gas in this order
        // highest offered price (in RING)
        uint128 lastRecord;
        // bidder who offer the highest price
        address lastBidder;
        // latestBidder's bidTime in timestamp
        uint lastBidStartAt;
    }

    // Reference to contract tracking NFT ownership
    ERC721Basic public nonFungibleContract;

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    // Map from token ID to their corresponding auction.
    mapping(uint256 => Auction) tokenIdToAuction;

    //add address of RING
    ERC20 public RING;

    // address of tokenvendor which exchange eth to ring or ring to eth
    TokenVendor public tokenVendor;

    //  TODO: add bidWaitingTime
    // necessary period of time from invoking bid action to successfully taking the land asset.
    // if someone else bid the same auction with higher price and within bidWaitingTime, your bid failed.
    uint public bidWaitingTime;



    event AuctionCreated(uint256 tokenId, uint256 startingPriceInRING, uint256 endingPriceInRING, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    //TODO: new bid event
    event NewBid(uint256 indexed tokenId, address lastBidder, uint256 lastRecord, uint256 bidStartAt);

    /// @dev DON'T give me your money.
    function() external {}

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

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.safeTransferFrom(_owner, this, _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.safeTransferFrom(this, _receiver, _tokenId);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes, "duration must be at least 1 minutes");

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPriceInRING),
            uint256(_auction.endingPriceInRING),
            uint256(_auction.duration)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }


    /// @dev Removes an auction from the list of open auctions.
    /// @param _tokenId - ID of NFT on auction.
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    // @dev return current price in ETH
    function _currentPriceETH(Auction storage _auction)
    internal
    view
    returns (uint256) {
        return (_currentPriceInRING(_auction) / getExchangeRate());
    }

    /// @dev Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _currentPriceInRING(Auction storage _auction)
    internal
    view
    returns (uint256)
    {
        uint256 secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn't ever go backwards).
        // TODO: modify currentPriceINRING logic
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }
        // if no one has bidden for _auction, compute the price as below.
        if (_auction.lastRecord == 0) {
            return _computeCurrentPriceInRING(
                _auction.startingPriceInRING,
                _auction.endingPriceInRING,
                _auction.duration,
                secondsPassed
            );
        } else {
            // compatible with first bid
            // as long as price_offered_by_buyer >= 1.1 * currentPice,
            // this buyer will be the lastBidder
            return ( 11 * _auction.lastRecord / 10);
        }


    }

    /// @dev Computes the current price of an auction. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function public and turn on
    ///  `Current price computation` test suite.
    function _computeCurrentPriceInRING(
        uint256 _startingPriceInRING,
        uint256 _endingPriceInRING,
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
            return _endingPriceInRING;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceInRINGChange = int256(_endingPriceInRING) - int256(_startingPriceInRING);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceInRINGChange = totalPriceInRINGChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPriceInRING = int256(_startingPriceInRING) + currentPriceInRINGChange;

            return uint256(currentPriceInRING);
        }
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerCut / 10000;
    }


    function _setTokenVendor(address _tokenVendor) internal {
        tokenVendor = TokenVendor(_tokenVendor);
    }

    function _setRING(address _ring) internal {
        RING = ERC20(_ring);
    }


    //TODO: add _setBidWaitingTime
    function _setBidWaitingTime(uint _waitingMinutes) internal {
        bidWaitingTime = _waitingMinutes * 1 minutes;
    }

    // TODO: get auction's real price
    // @dev return price of _auction (in RING)
    function _getRealPrice(Auction storage _auction) internal returns (uint){
        return _auction.lastRecord;
    }


    //  getexchangerate from tokenVendor
    function getExchangeRate() public view returns (uint256){
        return tokenVendor.buyTokenRate();
    }



}
