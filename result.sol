pragma solidity ^0.4.24;

// File: contracts/auction/ILandData.sol

interface ILandData {

    function addLandPixel(uint256 _tokenId, uint256 _landAttribute) public;
    function batchAdd(uint256[] _tokenIds, uint256[] _landAttributes) public;
    function modifyAttibutes(uint _tokenId, uint _right, uint _left, uint _newValue) public;
    function getXY(uint _tokenId) public view returns (int16 x, int16 y);

    function getGoldRate(uint _tokenId) public view returns (uint);
    function getWoodRate(uint _tokenId) public view returns (uint);
    function getWaterRate(uint _tokenId) public view returns (uint);
    function getFireRate(uint _tokenId) public view returns (uint);
    function getSoilRate(uint _tokenId) public view returns (uint);

    function isReserved(uint256 _tokenId) public view returns (bool);
    function isSpecial(uint256 _tokenId) public view returns (bool);
    function hasBox(uint256 _tokenId) public view returns (bool);

    function getInfoFromAttibutes(uint256 _attibutes, uint _rightAt, uint _leftAt) public returns (uint);
    function encodeTokenId(int _x, int _y) pure public returns (uint);


}

// File: contracts/auction/ITokenVendor.sol

interface ITokenVendor {


    function buyTokenRate() public returns (uint256);

    function sellTokenRate() public returns (uint256);

    function totalBuyTokenTransfered() public returns (uint256);

    function totalBuyEtherCollected() public returns (uint256);

    function totalSellEthTransfered() public returns (uint256);

    function totalSellTokenCollected() public returns (uint256);

    function tokenFallback(address _from, uint256 _value, bytes _data) public;

    function buyToken(address _th) public payable returns (bool);

    function sellToken(address _th, uint256 _value) public returns (bool);

    function changeBuyTokenRate(uint256 _newBuyTokenRate) public;

    function changeSellTokenRate(uint256 _newSellTokenRate) public;

    function claimTokens(address _token) public;

}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/auction/RewardBox.sol

contract RewardBox is Ownable {
    using SafeMath for *;

    address public landData;

    // the key of resourcePool are 0,1,2,3,4
    // respectively refer to gold,wood,water,fire,soil
    mapping (uint256 => uint256) public resourcePool;

    // number of box left
    uint public totalBoxNotOpened;

    // this need to be created in ClockAuction cotnract
    constructor(address _landData, uint256[5] _resources) public {
        landData = _landData;
        totalBoxNotOpened = 176;
        for(uint i = 0; i < 5; i++) {
            _setResourcePool(i, _resources[i]);
        }
    }

    //TODO: consider authority again
    function unbox(uint256 _tokenId)
    public
    returns (uint, uint, uint, uint, uint){
        // this is invoked in auction.claimLandAsset
        require(msg.sender == owner);

        uint[5] memory resourcesReward;
        (resourcesReward[0], resourcesReward[1],
        resourcesReward[2], resourcesReward[3], resourcesReward[4]) = _computeReward();

        for(uint i = 0; i < 5; i++) {
            ILandData(landData).modifyAttibutes(_tokenId, 32+16*i, 47+16*i, resourcesReward[i]);
        }

        return (resourcesReward[0], resourcesReward[1], resourcesReward[2],
        resourcesReward[3], resourcesReward[4]);
    }

    // rewards ranges from [0, 2 * average_of_resourcePool_left]
    // if early players get high resourceReward, then the later ones will get lower.
    // in other words, if early players get low resourceReward, the later ones get higher.
    // think about snatching wechat's virtual red envelopes in groups.
    function _computeReward() internal returns(uint,uint,uint,uint,uint) {
        require(totalBoxNotOpened > 0);

        uint[5] memory resourceRewards;
        // from fomo3d
        // msg.sender is always address(auction),
        // so change msg.sender to tx.origin
        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(tx.origin)))) / (now)).add
                (block.number)
            )));


            for(uint i = 0; i < 5; i++) {
                if (totalBoxNotOpened > 1) {
                    // recources in resourcePool is set by owner
                    // nad totalBoxNotOpened is set by rules
                    // there is no need to consider overflow
                // goldReward, woodReward, waterReward, fireReward, soilReward
                resourceRewards[i] = seed % (2 * resourcePool[i] / totalBoxNotOpened);
                // update resourcePool
                _setResourcePool(i, resourcePool[i] - resourceRewards[i]);
                }

                if(totalBoxNotOpened == 1) {
                    resourceRewards[i] = resourcePool[i];
                    _setResourcePool(i, resourcePool[i] - resourceRewards[i]);
                }
        }

        totalBoxNotOpened--;

        return (resourceRewards[0],resourceRewards[1], resourceRewards[2], resourceRewards[3], resourceRewards[4]);

    }


    function _setResourcePool(uint _keyNumber, uint _resources) internal {
        require(_keyNumber >= 0 && _keyNumber < 5);
        resourcePool[_keyNumber] = _resources;
    }

}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: contracts/auction/ClockAuctionBase.sol

/// @title Auction Core
/// @dev Contains models, variables, and internal methods for the auction.
contract ClockAuctionBase {
    using SafeMath for *;
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
    ITokenVendor public tokenVendor;

    // genesis landholder, pangu is the creator of all in certain version of Chinese mythology.
    address public pangu;

    // address of reward boxes
    RewardBox public rewardBox;

    // address of LandData
    ILandData public landData;

    // necessary period of time from invoking bid action to successfully taking the land asset.
    // if someone else bid the same auction with higher price and within bidWaitingTime, your bid failed.
    uint public bidWaitingTime;

    // if someone successfully invokes claimLandAsset,
    // then he/she can get claimBounty as reward
    //token address => claimBounty of certain token
    //TODO: modify the type of claimBounty
    mapping (address => uint) public token2claimBounty;


    event AuctionCreated(uint256 tokenId, uint256 startingPriceInToken, uint256 endingPriceInToken, uint256 duration, address token);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    // new bid event

    event NewBid(uint256 indexed tokenId, address lastBidder, address lastReferer, uint256 lastRecord, address tokenAddress, uint256 bidStartAt);

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
            uint256(_auction.startingPriceInToken),
            uint256(_auction.endingPriceInToken),
            uint256(_auction.duration),
            _auction.token
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
        return (_currentPriceInToken(_auction) / getExchangeRate());
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
        uint256 claimBounty = token2claimBounty[_auction.token];

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
            return ( (11 * (uint256(_auction.lastRecord).sub(claimBounty)) / 10).add(claimBounty));
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
    view
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
        tokenVendor = ITokenVendor(_tokenVendor);
    }

    function _setRING(address _ring) internal {
        RING = ERC20(_ring);
    }


    function _setBidWaitingTime(uint _waitingMinutes) internal {
        bidWaitingTime = _waitingMinutes * 1 minutes;
    }

    //TODO:
    function _setClaimBounty(address _token, uint _claimBounty) internal {
        token2claimBounty[_token] = _claimBounty;
        emit ClaimBounty(_token, _claimBounty);
    }

    function _setPangu(address _pangu) internal {
        pangu = _pangu;
    }

    // getexchangerate from tokenVendor
    function getExchangeRate() public view returns (uint256) {
        return tokenVendor.buyTokenRate();
    }




}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/auction/AuctionRelated.sol

/// @title Clock auction for non-fungible tokens.
contract AuctionRelated is Pausable, ClockAuctionBase {


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
        address _seller,
        address _token
    )
    internal
    whenNotPaused
    canBeStoredWith128Bits(_startingPriceInToken)
    canBeStoredWith128Bits(_endingPriceInToken)
    canBeStoredWith64Bits(_duration)
    {
        require(_owns(_from, _tokenId), "you are not the owner, dont do this.");
        _escrow(_from, _tokenId);

        Auction memory auction = Auction(
            _seller,
            uint128(_startingPriceInToken),
            uint128(_endingPriceInToken),
            uint64(_duration),
            uint64(now),
            //TODO: add auction.token
            _token,
            // which refer to lastRecord, lastBidder, lastBidStartAt,lastReferer
            // all set to zero when initialized
            0,0x0,0,0x0
        );
        _addAuction(_tokenId, auction);
    }



    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
    public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller || msg.sender == owner);
        // once someone has bidden for this auction, no one has the right to cancel it.
        require(auction.lastBidder == 0x0);
        _cancelAuction(_tokenId,seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
    whenPaused
    onlyOwner
    public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        // once someone has bidden for this auction, no one has the right to cancel it.
        require(auction.lastBidder == 0x0);
        _cancelAuction(_tokenId, auction.seller);
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
        require(_isOnAuction(auction));
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
    /// 
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPriceInToken(uint256 _tokenId)
    public
    view
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPriceInToken(auction);
    }

    // to apply for the safeTransferFrom
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    )
    public
    returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }


    function setTokenVendor(address _tokenVendor) public onlyOwner {
        _setTokenVendor(_tokenVendor);
    }

    function setRING(address _ring) public onlyOwner {
        _setRING(_ring);
    }

    //@dev only NFT contract can invoke this
    //@param _from - owner of _tokenId
    function receiveApproval(
        address _from,
        uint256 _tokenId,
        bytes _extraData)
    public
    whenNotPaused
    {
        if (msg.sender == address(nonFungibleContract)) {
            uint256 startingPriceInRING;
            uint256 endingPriceInRING;
            uint256 duration;
            address seller;

            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize)
                startingPriceInRING := mload(add(ptr,132))
                endingPriceInRING := mload(add(ptr,164))
                duration := mload(add(ptr,196))
                seller := mload(add(ptr,228))
            }
            //TODO: add parameter _token
            _createAuction(_from, _tokenId, startingPriceInRING, endingPriceInRING, duration, seller,address(RING));
        }

    }

    //TODO: add createAuction for pangu
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        address _seller,
        address _token)
    public {
        require(msg.sender == pangu, "only pangu can call this");
        // pangu can only set its own as seller
        _createAuction(msg.sender, _tokenId, _startingPriceInToken, _endingPriceInToken, _duration, msg.sender, _token);
    }

    // get auction's price of last bidder offered
    // @dev return price of _auction (in RING)
    function getLastRecord(uint _tokenId) public returns (uint256) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        return auction.lastRecord;
    }

    function getLastBidder(uint _tokenId) public view returns (address) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        return auction.lastBidder;
    }

    function getLastBidStartAt(uint _tokenId) public view returns (uint256) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        return auction.lastBidStartAt;
    }

    // @dev if someone new wants to bid, the lowest price he/she need to afford
    function computeNextBidRecord(uint _tokenId) public returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return _currentPriceInToken(auction);
    }




}

// File: contracts/auction/ClockAuction.sol

contract ClockAuction is AuctionRelated {

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    ///  _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000. It can be considered as transaction fee.
    ///  bidWaitingMinutes - biggest waiting time from a bid's starting to ending(in minutes)
    constructor(
        address _nftAddress,
        address _RING,
        address _tokenVendor,
        address _pangu,
        address _landData
        )
    public {
        // set ownerCut to 4%
        ownerCut = 400;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        // InterfaceId_ERC721 = 0x80ac58cd;
        require(candidateContract.supportsInterface(0x80ac58cd));
        nonFungibleContract = candidateContract;
        _setRING(_RING);
        _setTokenVendor(_tokenVendor);
        // bidWatingTime is 30 minutes
        _setBidWaitingTime(30);
        // claimBounty of ring is 20 ring
        _setClaimBounty(_RING, 20000000000000000000);
        _setPangu(_pangu);
        landData = ILandData(_landData);
        // convert the first on into uint to avoid error
        // because the default type is uint8[]
        // members in resourcesPool refer to
        // goldPool, woodPool, waterPool, firePool, soilPool respectively
        uint[5] memory resourcesPool = [uint(10439), 419, 5258, 12200, 10826];
        rewardBox = new RewardBox(_landData, resourcesPool);
    }

    modifier isHuman() {
        require (msg.sender == tx.origin, "robot is not permitted");
        _;
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



    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bidWithETH(uint256 _tokenId, address _referer)
    public
    payable
    whenNotPaused
    {

        // _bid will throw if the bid or funds transfer fails
        _bidWithETH(_tokenId, msg.value, msg.sender, _referer);
    }


    /// @dev bid with eth(in wei). Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bidWithETH(uint256 _tokenId, uint256 _bidAmount, address _buyer, address _referer)
    internal
    returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        // can only bid the auction that allows ring
        require(auction.token == address(RING));

        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));

        // Check that the incoming bid is higher than the current
        // price
        uint256 priceInETH = _currentPriceETH(auction);
        // assure msg.value larger than current price in ring
        require(_bidAmount >= priceInETH,
            "your offer is lower than the current price, try again with a higher one.");

        // assure that this get ring back from tokenVendor
        require(tokenVendor.buyToken.value(_bidAmount)(address(this)));


        // if no one has bidden for auction, priceInRING is computed through linear operation
        // if someone has already bidden for it before, priceInRING is last bidder's offer
        uint priceInRING = _currentPriceInToken(auction);

        uint bidMoment = _buyProcess(_buyer, auction, priceInRING, _referer);

        // Tell the world!
        // 0x0 refers to ETH
        emit NewBid(_tokenId, _buyer, _referer, priceInRING, 0x0, bidMoment);

        return priceInRING;
    }



    // @dev bid with RING. Computes the price and transfers winnings.
    function _bidWithToken(address _from, uint256 _tokenId, uint256 _valueInToken, address _referer) internal returns (uint256){
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));

        // Check that the incoming bid is higher than the current price
        uint priceInToken = _currentPriceInToken(auction);
        require(_valueInToken >= priceInToken,
            "your offer is lower than the current price, try again with a higher one.");

        uint bidMoment = _buyProcess(_from, auction, priceInToken, _referer);

        // Tell the world!
        emit NewBid(_tokenId, _from, _referer, priceInToken, auction.token, bidMoment);

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

        Auction storage auction = tokenIdToAuction[tokenId];
        if(_isOnAuction(auction)) {
            if (msg.sender == auction.token) {
                //TODO: modified
                _bidWithToken(_from, tokenId, _valueInToken, referer);
            }
        }
    }

    // TODO: advice: offer some reward for the person who claimed
    // @dev claim _tokenId for auction's lastBidder
    function claimLandAsset(uint _tokenId) public isHuman {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));
        // at least bidWaitingTime after last bidder's bid moment,
        // and no one else has bidden during this bidWaitingTime,
        // then any one can claim this token(land) for lastBidder.
        require(now >= auction.lastBidStartAt + bidWaitingTime,
            "this auction has not finished yet, try again later");

        // if this land asset has reward box on it,
        // unboxing it will raise resource limit to this land
        if(landData.hasBox(_tokenId)) {
            rewardBox.unbox(_tokenId);
        }

        ERC20 token = ERC20(auction.token);
        address lastBidder = auction.lastBidder;
        uint lastRecord = auction.lastRecord;
        address lastReferer = auction.lastReferer;

        uint claimBounty = token2claimBounty[auction.token];
        // if Auction is sucessful, refererBounty is taken on by evolutionland
        uint refererBounty = _computeCut(lastRecord.sub(claimBounty) / 11);

        //prevent re-entry attack
        _removeAuction(_tokenId);

        _transfer(lastBidder, _tokenId);
        // if there is claimBounty, then reward who invoke this function
        if (claimBounty > 0) {
            require(token.transfer(msg.sender, claimBounty));
            require(token.transfer(lastReferer, refererBounty));
        }

        emit AuctionSuccessful(_tokenId, lastRecord, lastBidder);
    }


    // TODO: add _token to compatible backwards with ring and eth
    function _buyProcess(address _buyer, Auction storage _auction, uint _priceInToken, address _referer)
    internal
    canBeStoredWith128Bits(_priceInToken)
    returns (uint256){

        uint claimBounty = token2claimBounty[_auction.token];
        uint priceWithoutBounty = _priceInToken.sub(claimBounty);

        // last bidder's info
        address lastBidder;
        // last bidder's price
        uint lastRecord;
        // last bidder's referer
        address lastReferer;

        lastBidder = _auction.lastBidder;
        lastRecord = uint256(_auction.lastRecord);
        lastReferer = _auction.lastReferer;

        // modify bid-related member variables

        _auction.lastBidder = _buyer;
        _auction.lastRecord = uint128(_priceInToken);
        _auction.lastBidStartAt = now;
        _auction.lastReferer = _referer;

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = _auction.seller;

        // the first bid
        if (lastBidder == 0x0 && _priceInToken > 0) {
            //  Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            //  value <= price, so this subtraction can't go negative.)
            // TODO: token to the seller
            // we dont touch claimBounty
            uint256 sellerProceedsInToken = priceWithoutBounty - _computeCut(priceWithoutBounty);
            // transfer to the seller
            ERC20(_auction.token).transfer(seller, sellerProceedsInToken);
        }

        // TODO: the math calculation needs further check
        //  not the first bid
        if (lastRecord > 0 && lastBidder != 0x0) {
            // TODO: repair bug of first bid's time limitation
            // if this the first bid, there is no time limitation
            require(now <= _auction.lastBidStartAt + bidWaitingTime, "It's too late.");

            // _priceInToken that is larger than lastRecord
            // was assured in _currentPriceInRING(_auction)
            // here double check
            // 1.1*price + bounty - (price + bounty) = 0.1price
            // we dont touch claimBounty
            uint extraForEach = (_priceInToken.sub(lastRecord)) / 2;
            uint realReturn = extraForEach.sub(_computeCut(extraForEach));
            if (_referer == 0x0) {
                ERC20(_auction.token).transfer(seller, realReturn);
                ERC20(_auction.token).transfer(lastBidder, (realReturn + lastRecord));
            } else {
                ERC20(_auction.token).transfer(seller, realReturn);
                ERC20(_auction.token).transfer(lastBidder, ((9 * realReturn / 10) + lastRecord));
                ERC20(_auction.token).transfer(_referer, realReturn / 10);
            }

        }

        return _auction.lastBidStartAt;
    }


    //@ param _waitingMinutes - waiting time (in minutes)
    function setBidWaitingTime(uint _waitingMinutes) public onlyOwner {
        _setBidWaitingTime(_waitingMinutes);
    }

    function setClaimBounty(address _token, uint _claimBounty) public onlyOwner {
        _setClaimBounty(_token, _claimBounty);
    }

    function setPangu(address _pangu) public onlyOwner {
        _setPangu(_pangu);
    }

//    function bytesToUint256(bytes b) public pure returns (uint256) {
//        bytes32 out;
//
//        for (uint i = 0; i < 32; i++) {
//            out |= bytes32(b[i] & 0xFF) >> (i * 8);
//        }
//        return uint256(out);
//    }


}
