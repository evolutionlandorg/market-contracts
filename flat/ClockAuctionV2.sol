// Dependency file: openzeppelin-solidity/contracts/introspection/ERC165.sol

// pragma solidity ^0.4.24;


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


// Dependency file: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/introspection/ERC165.sol";


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256('exists(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256('totalSupply()')) ^
   *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *   bytes4(keccak256('tokenByIndex(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256('name()')) ^
   *   bytes4(keccak256('symbol()')) ^
   *   bytes4(keccak256('tokenURI(uint256)'))
   */

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


// Dependency file: openzeppelin-solidity/contracts/math/SafeMath.sol

// pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


// Dependency file: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

// pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


// Dependency file: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


// Dependency file: @evolutionland/common/contracts/interfaces/ISettingsRegistry.sol

// pragma solidity ^0.4.24;

contract ISettingsRegistry {
    enum SettingsValueTypes { NONE, UINT, STRING, ADDRESS, BYTES, BOOL, INT }

    function uintOf(bytes32 _propertyName) public view returns (uint256);

    function stringOf(bytes32 _propertyName) public view returns (string);

    function addressOf(bytes32 _propertyName) public view returns (address);

    function bytesOf(bytes32 _propertyName) public view returns (bytes);

    function boolOf(bytes32 _propertyName) public view returns (bool);

    function intOf(bytes32 _propertyName) public view returns (int);

    function setUintProperty(bytes32 _propertyName, uint _value) public;

    function setStringProperty(bytes32 _propertyName, string _value) public;

    function setAddressProperty(bytes32 _propertyName, address _value) public;

    function setBytesProperty(bytes32 _propertyName, bytes _value) public;

    function setBoolProperty(bytes32 _propertyName, bool _value) public;

    function setIntProperty(bytes32 _propertyName, int _value) public;

    function getValueTypeOf(bytes32 _propertyName) public view returns (uint /* SettingsValueTypes */ );

    event ChangeProperty(bytes32 indexed _propertyName, uint256 _type);
}

// Dependency file: @evolutionland/common/contracts/interfaces/ERC223.sol

// pragma solidity ^0.4.23;

contract ERC223 {
    function transfer(address to, uint amount, bytes data) public returns (bool ok);

    function transferFrom(address from, address to, uint256 amount, bytes data) public returns (bool ok);

    event ERC223Transfer(address indexed from, address indexed to, uint amount, bytes data);
}


// Dependency file: @evolutionland/common/contracts/interfaces/IAuthority.sol

// pragma solidity ^0.4.24;

contract IAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

// Dependency file: @evolutionland/common/contracts/DSAuth.sol

// pragma solidity ^0.4.24;

// import '/Users/echo/workspace/contract/evolutionlandorg/market-contracts/node_modules/@evolutionland/common/contracts/interfaces/IAuthority.sol';

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

/**
 * @title DSAuth
 * @dev The DSAuth contract is reference implement of https://github.com/dapphub/ds-auth
 * But in the isAuthorized method, the src from address(this) is remove for safty concern.
 */
contract DSAuth is DSAuthEvents {
    IAuthority   public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(IAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == owner) {
            return true;
        } else if (authority == IAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}


// Dependency file: @evolutionland/common/contracts/PausableDSAuth.sol

// pragma solidity ^0.4.24;

// import "@evolutionland/common/contracts/DSAuth.sol";


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract PausableDSAuth is DSAuth {
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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// Dependency file: @evolutionland/land/contracts/interfaces/ILandBase.sol

// pragma solidity ^0.4.24;

contract ILandBase {

    /*
     *  Event
     */
    event ModifiedResourceRate(uint indexed tokenId, address resourceToken, uint16 newResourceRate);
    event HasboxSetted(uint indexed tokenId, bool hasBox);

    event ChangedReourceRateAttr(uint indexed tokenId, uint256 attr);

    event ChangedFlagMask(uint indexed tokenId, uint256 newFlagMask);

    event CreatedNewLand(uint indexed tokenId, int x, int y, address beneficiary, uint256 resourceRateAttr, uint256 mask);

    function defineResouceTokenRateAttrId(address _resourceToken, uint8 _attrId) public;

    function setHasBox(uint _landTokenID, bool isHasBox) public;
    function isReserved(uint256 _tokenId) public view returns (bool);
    function isSpecial(uint256 _tokenId) public view returns (bool);
    function isHasBox(uint256 _tokenId) public view returns (bool);

    function getResourceRateAttr(uint _landTokenId) public view returns (uint256);
    function setResourceRateAttr(uint _landTokenId, uint256 _newResourceRateAttr) public;

    function getResourceRate(uint _landTokenId, address _resouceToken) public view returns (uint16);
    function setResourceRate(uint _landTokenID, address _resourceToken, uint16 _newResouceRate) public;

    function getFlagMask(uint _landTokenId) public view returns (uint256);

    function setFlagMask(uint _landTokenId, uint256 _newFlagMask) public;

}

// Dependency file: @evolutionland/land/contracts/interfaces/IMysteriousTreasure.sol

// pragma solidity ^0.4.24;

contract IMysteriousTreasure {

    function unbox(uint256 _tokenId) public returns (uint, uint, uint, uint, uint);

}

// Dependency file: @evolutionland/common/contracts/SettingIds.sol

// pragma solidity ^0.4.24;

/**
    Id definitions for SettingsRegistry.sol
    Can be used in conjunction with the settings registry to get properties
*/
contract SettingIds {
    bytes32 public constant CONTRACT_RING_ERC20_TOKEN = "CONTRACT_RING_ERC20_TOKEN";

    bytes32 public constant CONTRACT_KTON_ERC20_TOKEN = "CONTRACT_KTON_ERC20_TOKEN";

    bytes32 public constant CONTRACT_GOLD_ERC20_TOKEN = "CONTRACT_GOLD_ERC20_TOKEN";

    bytes32 public constant CONTRACT_WOOD_ERC20_TOKEN = "CONTRACT_WOOD_ERC20_TOKEN";

    bytes32 public constant CONTRACT_WATER_ERC20_TOKEN = "CONTRACT_WATER_ERC20_TOKEN";

    bytes32 public constant CONTRACT_FIRE_ERC20_TOKEN = "CONTRACT_FIRE_ERC20_TOKEN";

    bytes32 public constant CONTRACT_SOIL_ERC20_TOKEN = "CONTRACT_SOIL_ERC20_TOKEN";

    bytes32 public constant CONTRACT_OBJECT_OWNERSHIP = "CONTRACT_OBJECT_OWNERSHIP";

    bytes32 public constant CONTRACT_TOKEN_LOCATION = "CONTRACT_TOKEN_LOCATION";

    bytes32 public constant CONTRACT_LAND_BASE = "CONTRACT_LAND_BASE";

    bytes32 public constant CONTRACT_USER_POINTS = "CONTRACT_USER_POINTS";

    bytes32 public constant CONTRACT_INTERSTELLAR_ENCODER = "CONTRACT_INTERSTELLAR_ENCODER";

    bytes32 public constant CONTRACT_DIVIDENDS_POOL = "CONTRACT_DIVIDENDS_POOL";

    bytes32 public constant CONTRACT_TOKEN_USE = "CONTRACT_TOKEN_USE";

    bytes32 public constant CONTRACT_REVENUE_POOL = "CONTRACT_REVENUE_POOL";

    bytes32 public constant CONTRACT_ERC721_BRIDGE = "CONTRACT_ERC721_BRIDGE";

    bytes32 public constant CONTRACT_PET_BASE = "CONTRACT_PET_BASE";

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // this can be considered as transaction fee.
    // Values 0-10,000 map to 0%-100%
    // set ownerCut to 4%
    // ownerCut = 400;
    bytes32 public constant UINT_AUCTION_CUT = "UINT_AUCTION_CUT";  // Denominator is 10000

    bytes32 public constant UINT_TOKEN_OFFER_CUT = "UINT_TOKEN_OFFER_CUT";  // Denominator is 10000

    // Cut referer takes on each auction, measured in basis points (1/100 of a percent).
    // which cut from transaction fee.
    // Values 0-10,000 map to 0%-100%
    // set refererCut to 4%
    // refererCut = 400;
    bytes32 public constant UINT_REFERER_CUT = "UINT_REFERER_CUT";

    bytes32 public constant CONTRACT_LAND_RESOURCE = "CONTRACT_LAND_RESOURCE";
}

// Dependency file: contracts/auction/AuctionSettingIds.sol

// pragma solidity ^0.4.24;

// import "@evolutionland/common/contracts/SettingIds.sol";

contract AuctionSettingIds is SettingIds {

    bytes32 public constant CONTRACT_CLOCK_AUCTION = "CONTRACT_CLOCK_AUCTION";

    // BidWaitingTime in seconds, default is 30 minutes
    // necessary period of time from invoking bid action to successfully taking the land asset.
    // if someone else bid the same auction with higher price and within bidWaitingTime, your bid failed.
    bytes32 public constant UINT_AUCTION_BID_WAITING_TIME = "UINT_AUCTION_BID_WAITING_TIME";


    bytes32 public constant CONTRACT_MYSTERIOUS_TREASURE = "CONTRACT_MYSTERIOUS_TREASURE";

    // users change eth(in wei) into ring with bancor exchange
    // which introduce bancor protocol to regulate the price of ring
    bytes32 public constant CONTRACT_BANCOR_EXCHANGE = "BANCOR_EXCHANGE";

    bytes32 public constant CONTRACT_POINTS_REWARD_POOL = "CONTRACT_POINTS_REWARD_POOL";

    // value belongs to [0, 10000000]
    bytes32 public constant UINT_EXCHANGE_ERROR_SPACE = "UINT_EXCHANGE_ERROR_SPACE";

    // "CONTRACT_CONTRIBUTION_INCENTIVE_POOL" is too long for byted32
    // so compress it to what states below
    bytes32 public constant CONTRACT_CONTRIBUTION_INCENTIVE_POOL = "CONTRACT_CONTRIBUTION_POOL";

    bytes32 public constant CONTRACT_DEV_POOL = "CONTRACT_DEV_POOL";

}


// Dependency file: contracts/auction/interfaces/IBancorExchange.sol

// pragma solidity ^0.4.23;

contract IBancorExchange {

    function buyRING(uint _minReturn) payable public returns (uint);
    function buyRINGInMinRequiedETH(uint _minReturn, address _buyer, uint _errorSpace) payable public returns (uint, uint);
}

// Root file: contracts/auction/ClockAuctionV2.sol

pragma solidity ^0.4.23;

// import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "@evolutionland/common/contracts/interfaces/ERC223.sol";
// import "@evolutionland/common/contracts/PausableDSAuth.sol";
// import "@evolutionland/land/contracts/interfaces/ILandBase.sol";
// import "@evolutionland/land/contracts/interfaces/IMysteriousTreasure.sol";
// import "contracts/auction/AuctionSettingIds.sol";
// import "contracts/auction/interfaces/IBancorExchange.sol";

contract ClockAuctionV2 is PausableDSAuth, AuctionSettingIds {
    using SafeMath for *;
    event AuctionCreated(
        uint256 tokenId, address seller, uint256 startingPriceInToken, uint256 endingPriceInToken, uint256 duration, address token
    );

    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    // new bid event
    event NewBid(
        uint256 indexed tokenId, address lastBidder, address lastReferer, uint256 lastRecord, address tokenAddress, uint256 bidStartAt, uint256 returnToLastBidder
    );

    // new bid event with eth
    event NewBidWithETH(uint256 indexed tokenId, address lastBidder, address lastReferer, uint256 ethRequired, uint256 lastRecord, address tokenAddress, uint256 bidStartAt, uint256 returnToLastBidder);

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint48 startedAt;
        // Duration (in seconds) of auction
        uint48 duration;
        // Price (in token) at beginning of auction
        uint128 startingPriceInToken;
        // Price (in token) at end of auction
        uint128 endingPriceInToken;
        // bid the auction through which token
        address token;

        // it saves gas in this order
        // highest offered price (in RING)
        uint128 lastRecord;
        // bidder who offer the highest price
        address lastBidder;
        // latestBidder's bidTime in timestamp
        uint48 lastBidStartAt;
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
    modifier canBeStoredWith48Bits(uint256 _value) {
        require(_value <= 281474976710656);
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
    public auth {
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
        (uint256 ringFromETH, uint256 ethRequired) = bancorExchange.buyRINGInMinRequiedETH.value(msg.value)(priceInRING, msg.sender, errorSpace);

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
        emit NewBidWithETH(_tokenId, msg.sender, _referer, ethRequired, priceInRING, 0x0, bidMoment, returnToLastBidder);

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
        _auction.lastBidStartAt = uint48(now);
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
        uint realReturnForEach = (surplus - poolCutAmount) / 2;
        uint returnToLastBidder = realReturnForEach + uint256(_auction.lastRecord);

        // here use transfer(address,uint256) for safety
        ERC223(_auction.token).transfer(_auction.seller, realReturnForEach, toBytes(_buyer));
        ERC20(_auction.token).transfer(_auction.lastBidder, returnToLastBidder);

        if (_referer != 0x0) {
            uint refererBounty = computeCut(poolCutAmount, _refererCut);
            ERC20(_auction.token).transfer(_referer, refererBounty);
            ERC223(_auction.token).transfer(_pool, (poolCutAmount - refererBounty), toBytes(_buyer));
        } else {
            ERC223(_auction.token).transfer(_pool, poolCutAmount, toBytes(_buyer));
        }

        // modify bid-related member variables
        _auction.lastBidder = _buyer;
        _auction.lastRecord = uint128(_priceInToken);
        _auction.lastBidStartAt = uint48(now);
        _auction.lastReferer = _referer;

        return (_auction.lastBidStartAt, returnToLastBidder);
    }

    // TODO: add _token to compatible backwards with ring and eth
    function _bidProcess(address _buyer, Auction storage _auction, uint _priceInToken, address _referer)
    internal
    canBeStoredWith128Bits(_priceInToken)
    returns (uint256, uint256){

        uint auctionCut = registry.uintOf(UINT_AUCTION_CUT);
        uint256 refererCut = registry.uintOf(UINT_REFERER_CUT);
        address revenuePool = registry.addressOf(CONTRACT_REVENUE_POOL);

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
    canBeStoredWith128Bits(_startingPriceInToken)
    canBeStoredWith128Bits(_endingPriceInToken)
    canBeStoredWith48Bits(_duration)
    canBeStoredWith48Bits(_startAt)
    whenNotPaused
    {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_duration >= 1 minutes, "duration must be at least 1 minutes");
        require(_duration <= 1000 days);

        // escrow
        ERC721Basic(registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP)).safeTransferFrom(_from, this, _tokenId);

        tokenIdToAuction[_tokenId] = Auction({
            seller: _seller,
            startedAt: uint48(_startAt),
            duration: uint48(_duration),
            startingPriceInToken: uint128(_startingPriceInToken),
            endingPriceInToken: uint128(_endingPriceInToken),
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
