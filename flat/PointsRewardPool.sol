// Dependency file: @evolutionland/common/contracts/interfaces/IAuthority.sol

// pragma solidity ^0.4.24;

contract IAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

// Dependency file: @evolutionland/common/contracts/DSAuth.sol

// pragma solidity ^0.4.24;

// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/common/contracts/interfaces/IAuthority.sol';

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


// Dependency file: @evolutionland/common/contracts/interfaces/ERC223ReceivingContract.sol

// pragma solidity ^0.4.23;

 /*
 * Contract that is working with ERC223 tokens
 * https://github.com/ethereum/EIPs/issues/223
 */

/// @title ERC223ReceivingContract - Standard contract implementation for compatibility with ERC223 tokens.
contract ERC223ReceivingContract {

    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _from Transaction initiator, analogue of msg.sender
    /// @param _value Number of tokens to transfer.
    /// @param _data Data containig a function signature and/or parameters
    function tokenFallback(address _from, uint256 _value, bytes _data) public;

}


// Dependency file: @evolutionland/common/contracts/interfaces/ERC223.sol

// pragma solidity ^0.4.23;

contract ERC223 {
    function transfer(address to, uint amount, bytes data) public returns (bool ok);

    function transferFrom(address from, address to, uint256 amount, bytes data) public returns (bool ok);

    event ERC223Transfer(address indexed from, address indexed to, uint amount, bytes data);
}


// Dependency file: @evolutionland/common/contracts/interfaces/IUserPoints.sol

// pragma solidity ^0.4.24;

contract IUserPoints {
    event AddedPoints(address indexed user, uint256 pointAmount);
    event SubedPoints(address indexed user, uint256 pointAmount);

    function addPoints(address _user, uint256 _pointAmount) public;

    function subPoints(address _user, uint256 _pointAmount) public;

    function pointsSupply() public view returns (uint256);

    function pointsBalanceOf(address _user) public view returns (uint256);
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


// Dependency file: contracts/auction/RevenuePool.sol

// pragma solidity ^0.4.24;

// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "@evolutionland/common/contracts/interfaces/ERC223ReceivingContract.sol";
// import "@evolutionland/common/contracts/interfaces/ERC223.sol";
// import "@evolutionland/common/contracts/interfaces/IUserPoints.sol";
// import "@evolutionland/common/contracts/DSAuth.sol";
// import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
// import "contracts/auction/AuctionSettingIds.sol";

// Use proxy mode
contract RevenuePool is DSAuth, ERC223ReceivingContract, AuctionSettingIds {

    bool private singletonLock = false;

//    // 10%
//    address public pointsRewardPool;
//    // 30%
//    address public contributionIncentivePool;
//    // 30%
//    address public dividendsPool;
//    // 30%
//    address public devPool;

    ISettingsRegistry public registry;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract(address _registry) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        registry = ISettingsRegistry(_registry);
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public {

        address ring = registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN);
        address userPoints = registry.addressOf(SettingIds.CONTRACT_USER_POINTS);

        if(msg.sender == ring) {
            address buyer = bytesToAddress(_data);
            // should same with trading reward percentage in settleToken;

            IUserPoints(userPoints).addPoints(buyer, _value / 1000);
        }
    }


    function settleToken(address _tokenAddress) public {
        uint balance = ERC20(_tokenAddress).balanceOf(address(this));

        // to save gas when playing
        if (balance > 10) {
            address pointsRewardPool = registry.addressOf(AuctionSettingIds.CONTRACT_POINTS_REWARD_POOL);
            address contributionIncentivePool = registry.addressOf(AuctionSettingIds.CONTRACT_CONTRIBUTION_INCENTIVE_POOL);
            address dividendsPool = registry.addressOf(CONTRACT_DIVIDENDS_POOL);
            address devPool = registry.addressOf(AuctionSettingIds.CONTRACT_DEV_POOL);

            require(pointsRewardPool != 0x0 && contributionIncentivePool != 0x0 && dividendsPool != 0x0 && devPool != 0x0);

            require(ERC223(_tokenAddress).transfer(pointsRewardPool, balance / 10, "0x0"));
            require(ERC223(_tokenAddress).transfer(contributionIncentivePool, balance * 3 / 10, "0x0"));
            require(ERC223(_tokenAddress).transfer(dividendsPool, balance * 3 / 10, "0x0"));
            require(ERC223(_tokenAddress).transfer(devPool, balance * 3 / 10, "0x0"));
        }

    }


    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public auth {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, msg.sender, balance);
    }

    function bytesToAddress(bytes b) public pure returns (address) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return address(out);
    }

}


// Root file: contracts/auction/PointsRewardPool.sol

pragma solidity ^0.4.24;

// import "@evolutionland/common/contracts/PausableDSAuth.sol";
// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "contracts/auction/RevenuePool.sol";
// import "contracts/auction/AuctionSettingIds.sol";

contract PointsRewardPool is PausableDSAuth, AuctionSettingIds {
    using SafeMath for *;

    event RewardClaimedWithPoints(address indexed user, uint256 pointAmount, uint256 rewardAmount);

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    modifier isHuman() {
        require(msg.sender == tx.origin, "robot is not permitted");
        _;
    }

    /*
     * Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    constructor() public {
        // initializeContract
    }

    function initializeContract(address _registry) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = ISettingsRegistry(_registry);
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public {
        return;
    }

    function playWithSmallTicket() public isHuman whenNotPaused {
        _play(10 ether, 8);
    }

    function playWithLargeTicket() public isHuman whenNotPaused {
        _play(100 ether, 10);
    }

    function totalRewardInPool(address _token) public view returns (uint256) {
        return ERC20(_token).balanceOf(address(this)) + ERC20(_token).balanceOf(registry.addressOf(CONTRACT_REVENUE_POOL)) / 10;
    }

    function _play(uint _pointAmount, uint _houseEdgeDenominator) internal {
        // settlement by the way.
        address revenuePool = registry.addressOf(CONTRACT_REVENUE_POOL);
        IUserPoints userPoints = IUserPoints(registry.addressOf(CONTRACT_USER_POINTS));

        RevenuePool(revenuePool)
            .settleToken(registry.addressOf(CONTRACT_RING_ERC20_TOKEN));

        userPoints.subPoints(msg.sender, _pointAmount);

        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(tx.origin)))) / (now)).add
                (block.number)
            )));

        // first part
        uint256 rewardPoints = (seed % _pointAmount).mul(_houseEdgeDenominator - 1).div(_houseEdgeDenominator); 

        // second part.
        if (seed % _houseEdgeDenominator == 0) {
            rewardPoints = rewardPoints.add(_pointAmount.mul(_houseEdgeDenominator - 1).div(2));
        } else if (seed % _houseEdgeDenominator == 1) {
            rewardPoints = 0;
        }

        address ring = registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN);

        uint256 pointsSupply = userPoints.pointsSupply();

        if (rewardPoints > pointsSupply) {
            rewardPoints = pointsSupply;
        }

        uint256 rewardTokens = rewardPoints.mul(ERC20(ring).balanceOf(address(this))).div(pointsSupply);

        ERC20(ring).transfer(msg.sender, rewardTokens);

        emit RewardClaimedWithPoints(msg.sender, _pointAmount, rewardTokens);
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public auth {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

}