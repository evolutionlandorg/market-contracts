pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "@evolutionland/common/contracts/interfaces/ILandData.sol";
import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "./interfaces/IClaimBountyCalculator.sol";
import "./AuctionSettingIds.sol";
import "./interfaces/IBancorExchange.sol";

/// @title Auction Core
/// @dev Contains models, variables, and internal methods for the auction.
contract ClockAuctionBase is Pausable, AuctionSettingIds {
    using SafeMath for *;
    uint constant COIN = 10**18;

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
        //TODO: add token address
        // bid the auction through which token
        address token;

        // it saves gas in this order
        // highest offered price (in RING)
        uint128 lastRecord;
        // bidder who offer the highest price
        address lastBidder;
        // latestBidder's bidTime in timestamp
        uint256 lastBidStartAt;
        // lastBidder's referer
        address lastReferer;
    }

    ISettingsRegistry registry;

    // Reference to contract tracking NFT ownership
    ERC721Basic public nonFungibleContract;

    // Map from token ID to their corresponding auction.
    mapping(uint256 => Auction) tokenIdToAuction;

    //add address of RING
    ERC20 public RING;

    // address of bancorExchange which exchange eth to ring or ring to eth
    // IBancorExchange public bancorExchange;

    // genesis landholder, pangu is the creator of all in certain version of Chinese mythology.
    address public pangu;

    event AuctionCreated(uint256 tokenId, address seller, uint256 startingPriceInToken, uint256 endingPriceInToken, uint256 duration, address token);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    // new bid event
    event NewBid(uint256 indexed tokenId, address lastBidder, address lastReferer, uint256 lastRecord, address tokenAddress, uint256 bidStartAt, uint256 returnToLastBidder);

    // set claimBounty
    event ClaimBounty(address indexed _token, uint256 indexed _claimBounty);

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
        require((nonFungibleContract.ownerOf(_tokenId) == _from), "you are not the owner, dont do this.");

        // escrow
        nonFungibleContract.safeTransferFrom(_from, this, _tokenId);

        Auction memory auction = Auction(
            _seller,
            uint128(_startingPriceInToken),
            uint128(_endingPriceInToken),
            uint64(_duration),
            uint64(_startAt),
            //TODO: add auction.token
            _token,
            // which refer to lastRecord, lastBidder, lastBidStartAt,lastReferer
            // all set to zero when initialized
            0,0x0,0,0x0
        );
        
        _addAuction(_tokenId, auction);
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
            _auction.seller,
            uint256(_auction.startingPriceInToken),
            uint256(_auction.endingPriceInToken),
            uint256(_auction.duration),
            _auction.token
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        nonFungibleContract.safeTransferFrom(this, _seller, _tokenId);
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


    /// @dev Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _currentPriceInToken(Auction storage _auction)
    internal
    view
    returns (uint256)
    {
        uint256 secondsPassed = 0;

        // get bounty of certain token
        IClaimBountyCalculator claimBountyCalculator = IClaimBountyCalculator(registry.addressOf(AuctionSettingIds.CONTRACT_AUCTION_CLAIM_BOUNTY));
        
        uint256 claimBounty = claimBountyCalculator.tokenAmountForBounty(_auction.token);

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn't ever go backwards).
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }
        // if no one has bidden for _auction, compute the price as below.
        if (_auction.lastRecord == 0) {
            return _computeCurrentPriceInToken(
                _auction.startingPriceInToken,
                _auction.endingPriceInToken,
                _auction.duration,
                secondsPassed,
                claimBounty
            );
        } else {
            // compatible with first bid
            // as long as price_offered_by_buyer >= 1.1 * currentPice,
            // this buyer will be the lastBidder
            // 1.1 * (lastRecord - claimBounty) + claimBounty
            return ((11 * (uint256(_auction.lastRecord).sub(claimBounty)) / 10).add(claimBounty));
        }

    }


    /// @dev Computes the current price of an auction. Factored out
    ///  from _currentPrice so we can run extensive unit tests.
    ///  When testing, make this function public and turn on
    ///  `Current price computation` test suite.
    function _computeCurrentPriceInToken(
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _secondsPassed,
        uint256 _claimBounty
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

            return (uint256(currentPriceInToken) + _claimBounty);
        }
    }


    function _setPangu(address _pangu) internal {
        pangu = _pangu;
    }


}