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


// Dependency file: @evolutionland/common/contracts/SettingsRegistry.sol

// pragma solidity ^0.4.24;

// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "@evolutionland/common/contracts/DSAuth.sol";

/**
 * @title SettingsRegistry
 * @dev This contract holds all the settings for updating and querying.
 */
contract SettingsRegistry is ISettingsRegistry, DSAuth {

    mapping(bytes32 => uint256) public uintProperties;
    mapping(bytes32 => string) public stringProperties;
    mapping(bytes32 => address) public addressProperties;
    mapping(bytes32 => bytes) public bytesProperties;
    mapping(bytes32 => bool) public boolProperties;
    mapping(bytes32 => int256) public intProperties;

    mapping(bytes32 => SettingsValueTypes) public valueTypes;

    function uintOf(bytes32 _propertyName) public view returns (uint256) {
        require(valueTypes[_propertyName] == SettingsValueTypes.UINT, "Property type does not match.");
        return uintProperties[_propertyName];
    }

    function stringOf(bytes32 _propertyName) public view returns (string) {
        require(valueTypes[_propertyName] == SettingsValueTypes.STRING, "Property type does not match.");
        return stringProperties[_propertyName];
    }

    function addressOf(bytes32 _propertyName) public view returns (address) {
        require(valueTypes[_propertyName] == SettingsValueTypes.ADDRESS, "Property type does not match.");
        return addressProperties[_propertyName];
    }

    function bytesOf(bytes32 _propertyName) public view returns (bytes) {
        require(valueTypes[_propertyName] == SettingsValueTypes.BYTES, "Property type does not match.");
        return bytesProperties[_propertyName];
    }

    function boolOf(bytes32 _propertyName) public view returns (bool) {
        require(valueTypes[_propertyName] == SettingsValueTypes.BOOL, "Property type does not match.");
        return boolProperties[_propertyName];
    }

    function intOf(bytes32 _propertyName) public view returns (int) {
        require(valueTypes[_propertyName] == SettingsValueTypes.INT, "Property type does not match.");
        return intProperties[_propertyName];
    }

    function setUintProperty(bytes32 _propertyName, uint _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.UINT, "Property type does not match.");
        uintProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.UINT;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.UINT));
    }

    function setStringProperty(bytes32 _propertyName, string _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.STRING, "Property type does not match.");
        stringProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.STRING;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.STRING));
    }

    function setAddressProperty(bytes32 _propertyName, address _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.ADDRESS, "Property type does not match.");

        addressProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.ADDRESS;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.ADDRESS));
    }

    function setBytesProperty(bytes32 _propertyName, bytes _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.BYTES, "Property type does not match.");

        bytesProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.BYTES;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.BYTES));
    }

    function setBoolProperty(bytes32 _propertyName, bool _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.BOOL, "Property type does not match.");

        boolProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.BOOL;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.BOOL));
    }

    function setIntProperty(bytes32 _propertyName, int _value) public auth {
        require(
            valueTypes[_propertyName] == SettingsValueTypes.NONE || valueTypes[_propertyName] == SettingsValueTypes.INT, "Property type does not match.");

        intProperties[_propertyName] = _value;
        valueTypes[_propertyName] = SettingsValueTypes.INT;

        emit ChangeProperty(_propertyName, uint256(SettingsValueTypes.INT));
    }

    function getValueTypeOf(bytes32 _propertyName) public view returns (uint256 /* SettingsValueTypes */ ) {
        return uint256(valueTypes[_propertyName]);
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


// Dependency file: @evolutionland/common/contracts/interfaces/TokenController.sol

// pragma solidity ^0.4.23;


/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner, bytes4 sig, bytes data) payable public returns (bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns (bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public returns (bool);
}


// Dependency file: @evolutionland/common/contracts/interfaces/ApproveAndCallFallBack.sol

// pragma solidity ^0.4.23;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

// Dependency file: @evolutionland/common/contracts/interfaces/ERC223.sol

// pragma solidity ^0.4.23;

contract ERC223 {
    function transfer(address to, uint amount, bytes data) public returns (bool ok);

    function transferFrom(address from, address to, uint256 amount, bytes data) public returns (bool ok);

    event ERC223Transfer(address indexed from, address indexed to, uint amount, bytes data);
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


// Dependency file: @evolutionland/common/contracts/StandardERC20Base.sol

// pragma solidity ^0.4.23;

// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract StandardERC20Base is ERC20 {
    using SafeMath for uint256;
    
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    function totalSupply() public view returns (uint) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender) {
            _approvals[src][msg.sender] = _approvals[src][msg.sender].sub(wad);
        }

        _balances[src] = _balances[src].sub(wad);
        _balances[dst] = _balances[dst].add(wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }
}


// Dependency file: @evolutionland/common/contracts/StandardERC223.sol

// pragma solidity ^0.4.24;

// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/common/contracts/interfaces/ERC223ReceivingContract.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/common/contracts/interfaces/TokenController.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/common/contracts/interfaces/ApproveAndCallFallBack.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/common/contracts/interfaces/ERC223.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/common/contracts/StandardERC20Base.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/common/contracts/DSAuth.sol';

// This is a contract for demo and test.
contract StandardERC223 is StandardERC20Base, DSAuth, ERC223 {
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);

    bytes32  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize
    // Optional token name
    bytes32   public  name = "";

    address public controller;

    constructor(bytes32 _symbol) public {
        symbol = _symbol;
        controller = msg.sender;
    }

    function setName(bytes32 name_) public auth {
        name = name_;
    }

//////////
// Controller Methods
//////////
    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public auth {
        controller = _newController;
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {
        // Alerts the token controller of the transfer
        if (isContract(controller)) {
            if (!TokenController(controller).onTransfer(_from, _to, _amount))
               revert();
        }

        success = super.transferFrom(_from, _to, _amount);
    }

    /*
     * ERC 223
     * Added support for the ERC 223 "tokenFallback" method in a "transfer" function with a payload.
     */
    function transferFrom(address _from, address _to, uint256 _amount, bytes _data)
        public
        returns (bool success)
    {
        // Alerts the token controller of the transfer
        if (isContract(controller)) {
            if (!TokenController(controller).onTransfer(_from, _to, _amount))
               revert();
        }

        require(super.transferFrom(_from, _to, _amount));

        if (isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _amount, _data);
        }

        emit ERC223Transfer(_from, _to, _amount, _data);

        return true;
    }

    function issue(address _to, uint256 _amount) public auth {
        mint(_to, _amount);
    }

    function destroy(address _from, uint256 _amount) public auth {
        burn(_from, _amount);
    }

    function mint(address _to, uint _amount) public auth {
        _supply = _supply.add(_amount);
        _balances[_to] = _balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    function burn(address _who, uint _value) public auth {
        require(_value <= _balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        _balances[_who] = _balances[_who].sub(_value);
        _supply = _supply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    /*
     * ERC 223
     * Added support for the ERC 223 "tokenFallback" method in a "transfer" function with a payload.
     * https://github.com/ethereum/EIPs/issues/223
     * function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
     */
    /// @notice Send `_value` tokens to `_to` from `msg.sender` and trigger
    /// tokenFallback if sender is a contract.
    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _to Address of token receiver.
    /// @param _amount Number of tokens to transfer.
    /// @param _data Data to be sent to tokenFallback
    /// @return Returns success of function call.
    function transfer(
        address _to,
        uint256 _amount,
        bytes _data)
        public
        returns (bool success)
    {
        return transferFrom(msg.sender, _to, _amount, _data);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            if (!TokenController(controller).onApprove(msg.sender, _spender, _amount))
                revert();
        }
        
        return super.approve(_spender, _amount);
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        if (!approve(_spender, _amount)) revert();

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @notice The fallback function: If the contract's controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function ()  public payable {
        if (isContract(controller)) {
            if (! TokenController(controller).proxyPayment.value(msg.value)(msg.sender, msg.sig, msg.data))
                revert();
        } else {
            revert();
        }
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public auth {
        if (_token == 0x0) {
            address(msg.sender).transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(address(msg.sender), balance);

        emit ClaimedTokens(_token, address(msg.sender), balance);
    }

////////////////
// Events
////////////////

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}

// Dependency file: openzeppelin-solidity/contracts/ownership/Ownable.sol

// pragma solidity ^0.4.24;


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


// Dependency file: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}


// Dependency file: openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol

// pragma solidity ^0.4.24;


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}


// Dependency file: openzeppelin-solidity/contracts/AddressUtils.sol

// pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}


// Dependency file: openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/introspection/ERC165.sol";


/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


// Dependency file: openzeppelin-solidity/contracts/token/ERC721/ERC721BasicToken.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
// import "openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol";
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "openzeppelin-solidity/contracts/AddressUtils.sol";
// import "openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol";


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}


// Dependency file: openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
// import "openzeppelin-solidity/contracts/token/ERC721/ERC721BasicToken.sol";
// import "openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol";


/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    // To prevent a gap in the array, we store the last token in the index of the token to delete, and
    // then delete the last slot.
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    // This also deletes the contents at the last position of the array
    ownedTokens[_from].length--;

    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}


// Dependency file: @evolutionland/common/contracts/interfaces/IInterstellarEncoder.sol

// pragma solidity ^0.4.24;

contract IInterstellarEncoder {
    uint256 constant CLEAR_HIGH =  0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    uint256 public constant MAGIC_NUMBER = 42;    // Interstellar Encoding Magic Number.
    uint256 public constant CHAIN_ID = 1; // Ethereum mainet.
    uint256 public constant CURRENT_LAND = 1; // 1 is Atlantis, 0 is NaN.

    enum ObjectClass { 
        NaN,
        LAND,
        APOSTLE,
        OBJECT_CLASS_COUNT
    }

    function registerNewObjectClass(address _objectContract, uint8 objectClass) public;

    function registerNewTokenContract(address _tokenAddress) public;

    function encodeTokenId(address _tokenAddress, uint8 _objectClass, uint128 _objectIndex) public view returns (uint256 _tokenId);

    function encodeTokenIdForObjectContract(
        address _tokenAddress, address _objectContract, uint128 _objectId) public view returns (uint256 _tokenId);

    function getContractAddress(uint256 _tokenId) public view returns (address);

    function getObjectId(uint256 _tokenId) public view returns (uint128 _objectId);

    function getObjectClass(uint256 _tokenId) public view returns (uint8);

    function getObjectAddress(uint256 _tokenId) public view returns (address);
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

// Dependency file: @evolutionland/common/contracts/ObjectOwnership.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
// import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
// import "@evolutionland/common/contracts/interfaces/IInterstellarEncoder.sol";
// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "@evolutionland/common/contracts/DSAuth.sol";
// import "@evolutionland/common/contracts/SettingIds.sol";

contract ObjectOwnership is ERC721Token("Evolution Land Objects","EVO"), DSAuth, SettingIds {
    ISettingsRegistry public registry;

    bool private singletonLock = false;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    /**
     * @dev Atlantis's constructor 
     */
    constructor () public {
        // initializeContract();
    }

    /**
     * @dev Same with constructor, but is used and called by storage proxy as logic contract.
     */
    function initializeContract(address _registry) public singletonLockCall {
        // Ownable constructor
        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        // SupportsInterfaceWithLookup constructor
        _registerInterface(InterfaceId_ERC165);

        // ERC721BasicToken constructor
        _registerInterface(InterfaceId_ERC721);
        _registerInterface(InterfaceId_ERC721Exists);

        // ERC721Token constructor
        name_ = "Evolution Land Objects";
        symbol_ = "EVO";    // Evolution Land Objects
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721Enumerable);
        _registerInterface(InterfaceId_ERC721Metadata);

        registry = ISettingsRegistry(_registry);
    }

    function mintObject(address _to, uint128 _objectId) public auth returns (uint256 _tokenId) {
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);

        _tokenId = IInterstellarEncoder(interstellarEncoder).encodeTokenIdForObjectContract(
            address(this), msg.sender, _objectId);
        super._mint(_to, _tokenId);
    }

    function burnObject(address _to, uint128 _objectId) public auth returns (uint256 _tokenId) {
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);

        _tokenId = IInterstellarEncoder(interstellarEncoder).encodeTokenIdForObjectContract(
            address(this), msg.sender, _objectId);
        super._burn(_to, _tokenId);
    }

    function mint(address _to, uint256 _tokenId) public auth {
        super._mint(_to, _tokenId);
    }

    function burn(address _to, uint256 _tokenId) public auth {
        super._burn(_to, _tokenId);
    }

    //@dev user invoke approveAndCall to create auction
    //@param _to - address of auction contractß
    function approveAndCall(
        address _to,
        uint _tokenId,
        bytes _extraData
    ) public {
        // set _to to the auction contract
        approve(_to, _tokenId);

        if(!_to.call(
                bytes4(keccak256("receiveApproval(address,uint256,bytes)")), abi.encode(msg.sender, _tokenId, _extraData)
                )) {
            revert();
        }
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

// Dependency file: @evolutionland/common/contracts/interfaces/IObjectOwnership.sol

// pragma solidity ^0.4.24;

contract IObjectOwnership {
    function mintObject(address _to, uint128 _objectId) public returns (uint256 _tokenId);

    function burnObject(address _to, uint128 _objectId) public returns (uint256 _tokenId);
}

// Dependency file: @evolutionland/common/contracts/interfaces/ITokenLocation.sol

// pragma solidity ^0.4.24;

contract ITokenLocation {

    function hasLocation(uint256 _tokenId) public view returns (bool);

    function getTokenLocation(uint256 _tokenId) public view returns (int, int);

    function setTokenLocation(uint256 _tokenId, int _x, int _y) public;

    function getTokenLocationHM(uint256 _tokenId) public view returns (int, int);

    function setTokenLocationHM(uint256 _tokenId, int _x, int _y) public;
}

// Dependency file: @evolutionland/common/contracts/LocationCoder.sol

// pragma solidity ^0.4.24;

library LocationCoder {
    // the allocation of the [x, y, z] is [0<1>, x<21>, y<21>, z<21>]
    uint256 constant CLEAR_YZ = 0x0fffffffffffffffffffff000000000000000000000000000000000000000000;
    uint256 constant CLEAR_XZ = 0x0000000000000000000000fffffffffffffffffffff000000000000000000000;
    uint256 constant CLEAR_XY = 0x0000000000000000000000000000000000000000000fffffffffffffffffffff;

    uint256 constant NOT_ZERO = 0x1000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant APPEND_HIGH =  0xfffffffffffffffffffffffffffffffffffffffffff000000000000000000000;

    uint256 constant MAX_LOCATION_ID =    0x2000000000000000000000000000000000000000000000000000000000000000;

    int256 constant HMETER_DECIMAL  = 10 ** 8;

    // x, y, z should between -2^83 (-9671406556917033397649408) and 2^83 - 1 (9671406556917033397649407).
    int256 constant MIN_Location_XYZ = -9671406556917033397649408;
    int256 constant MAX_Location_XYZ = 9671406556917033397649407;
    // 96714065569170334.50000000
    int256 constant MAX_HM_DECIMAL  = 9671406556917033450000000;
    int256 constant MAX_HM  = 96714065569170334;

    function encodeLocationIdXY(int _x, int _y) internal pure  returns (uint result) {
        return encodeLocationId3D(_x, _y, 0);
    }

    function decodeLocationIdXY(uint _positionId) internal pure  returns (int _x, int _y) {
        (_x, _y, ) = decodeLocationId3D(_positionId);
    }

    function encodeLocationId3D(int _x, int _y, int _z) internal pure  returns (uint result) {
        return _unsafeEncodeLocationId3D(_x, _y, _z);
    }

    function _unsafeEncodeLocationId3D(int _x, int _y, int _z) internal pure returns (uint) {
        require(_x >= MIN_Location_XYZ && _x <= MAX_Location_XYZ, "Invalid value.");
        require(_y >= MIN_Location_XYZ && _y <= MAX_Location_XYZ, "Invalid value.");
        require(_z >= MIN_Location_XYZ && _z <= MAX_Location_XYZ, "Invalid value.");

        // uint256 constant FACTOR_2 = 0x1000000000000000000000000000000000000000000; // <16 ** 42> or <2 ** 168>
        // uint256 constant FACTOR = 0x1000000000000000000000; // <16 ** 21> or <2 ** 84>
        return ((uint(_x) << 168) & CLEAR_YZ) | (uint(_y << 84) & CLEAR_XZ) | (uint(_z) & CLEAR_XY) | NOT_ZERO;
    }

    function decodeLocationId3D(uint _positionId) internal pure  returns (int, int, int) {
        return _unsafeDecodeLocationId3D(_positionId);
    }

    function _unsafeDecodeLocationId3D(uint _value) internal pure  returns (int x, int y, int z) {
        require(_value >= NOT_ZERO && _value < MAX_LOCATION_ID, "Invalid Location Id");

        x = expandNegative84BitCast((_value & CLEAR_YZ) >> 168);
        y = expandNegative84BitCast((_value & CLEAR_XZ) >> 84);
        z = expandNegative84BitCast(_value & CLEAR_XY);
    }

    function toHM(int _x) internal pure returns (int) {
        return (_x + MAX_HM_DECIMAL)/HMETER_DECIMAL - MAX_HM;
    }

    function toUM(int _x) internal pure returns (int) {
        return _x * LocationCoder.HMETER_DECIMAL;
    }

    function expandNegative84BitCast(uint _value) internal pure  returns (int) {
        if (_value & (1<<83) != 0) {
            return int(_value | APPEND_HIGH);
        }
        return int(_value);
    }

    function encodeLocationIdHM(int _x, int _y) internal pure  returns (uint result) {
        return encodeLocationIdXY(toUM(_x), toUM(_y));
    }

    function decodeLocationIdHM(uint _positionId) internal pure  returns (int, int) {
        (int _x, int _y) = decodeLocationIdXY(_positionId);
        return (toHM(_x), toHM(_y));
    }
}

// Dependency file: @evolutionland/land/contracts/LandBase.sol

// pragma solidity ^0.4.24;

// import "@evolutionland/land/contracts/interfaces/ILandBase.sol";
// import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
// import "@evolutionland/common/contracts/interfaces/IObjectOwnership.sol";
// import "@evolutionland/common/contracts/interfaces/ITokenLocation.sol";
// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "@evolutionland/common/contracts/DSAuth.sol";
// import "@evolutionland/common/contracts/SettingIds.sol";
// import "@evolutionland/common/contracts/LocationCoder.sol";

contract LandBase is DSAuth, ILandBase, SettingIds {
    using LocationCoder for *;

    uint256 constant internal RESERVED = uint256(1);
    uint256 constant internal SPECIAL = uint256(2);
    uint256 constant internal HASBOX = uint256(4);

    uint256 constant internal CLEAR_RATE_HIGH = 0x000000000000000000000000000000000000000000000000000000000000ffff;

    struct LandAttr {
        uint256 resourceRateAttr;
        uint256 mask;
    }

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    /**
     * @dev mapping from resource token address to resource atrribute rate id.
     * atrribute rate id starts from 1 to 16, NAN is 0.
     * goldrate is 1, woodrate is 2, waterrate is 3, firerate is 4, soilrate is 5
     */
    mapping (address => uint8) public resourceToken2RateAttrId;

    /**
     * @dev mapping from token id to land resource atrribute.
     */
    mapping (uint256 => LandAttr) public tokenId2LandAttr;

    // mapping from position in map to token id.
    mapping (uint256 => uint256) public locationId2TokenId;

    uint256 public lastLandObjectId;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    modifier xAtlantisRangeLimit(int _x) {
        require(_x >= -112 && _x <= -68, "Invalid range.");
        _;
    }

    modifier yAtlantisRangeLimit(int _y) {
        require(_y >= -22 && _y <= 22, "Invalid range.");
        _;
    }

    /**
     * @dev Same with constructor, but is used and called by storage proxy as logic contract.
     */
    function initializeContract(address _registry) public singletonLockCall {
        // Ownable constructor
        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        registry = ISettingsRegistry(_registry);

         // update attributes.
        resourceToken2RateAttrId[registry.addressOf(CONTRACT_GOLD_ERC20_TOKEN)] = 1;
        resourceToken2RateAttrId[registry.addressOf(CONTRACT_WOOD_ERC20_TOKEN)] = 2;
        resourceToken2RateAttrId[registry.addressOf(CONTRACT_WATER_ERC20_TOKEN)] = 3;
        resourceToken2RateAttrId[registry.addressOf(CONTRACT_FIRE_ERC20_TOKEN)] = 4;
        resourceToken2RateAttrId[registry.addressOf(CONTRACT_SOIL_ERC20_TOKEN)] = 5;
    }

    /*
     * @dev assign new land
     */
    function assignNewLand(
        int _x, int _y, address _beneficiary, uint256 _resourceRateAttr, uint256 _mask
        ) public auth xAtlantisRangeLimit(_x) yAtlantisRangeLimit(_y) returns (uint _tokenId) {

        // auto increase object id, start from 1
        lastLandObjectId += 1;
        require(lastLandObjectId <= 340282366920938463463374607431768211455, "Can not be stored with 128 bits.");

        _tokenId = IObjectOwnership(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).mintObject(_beneficiary, uint128(lastLandObjectId));

        // update locations.
        uint256 locationId = LocationCoder.encodeLocationIdHM(_x, _y);
        require(locationId2TokenId[locationId] == 0, "Land in this position already been mint.");
        locationId2TokenId[locationId] = _tokenId;
        ITokenLocation(registry.addressOf(CONTRACT_TOKEN_LOCATION)).setTokenLocationHM(_tokenId, _x, _y);

        tokenId2LandAttr[_tokenId].resourceRateAttr = _resourceRateAttr;
        tokenId2LandAttr[_tokenId].mask = _mask;

        emit CreatedNewLand(_tokenId, _x, _y, _beneficiary, _resourceRateAttr, _mask);
    }

    function assignMultipleLands(
        int[] _xs, int[] _ys, address _beneficiary, uint256[] _resourceRateAttrs, uint256[] _masks
        ) public auth returns (uint[]){
        require(_xs.length == _ys.length, "Length of xs didn't match length of ys");
        require(_xs.length == _resourceRateAttrs.length, "Length of postions didn't match length of land attributes");
        require(_xs.length == _masks.length, "Length of masks didn't match length of ys");

        uint[] memory _tokenIds = new uint[](_xs.length);

        for (uint i = 0; i < _xs.length; i++) {
            _tokenIds[i] = assignNewLand(_xs[i], _ys[i], _beneficiary, _resourceRateAttrs[i], _masks[i]);
        }

        return _tokenIds;
    }

    function defineResouceTokenRateAttrId(address _resourceToken, uint8 _attrId) public auth {
        require(_attrId > 0 && _attrId <= 16, "Invalid Attr Id.");

        resourceToken2RateAttrId[_resourceToken] = _attrId;
    }

    // encode (x,y) to get tokenId
    function getTokenIdByLocation(int _x, int _y) public view returns (uint256) {
        uint locationId = LocationCoder.encodeLocationIdHM(_x, _y);
        return locationId2TokenId[locationId];
    }

    function exists(int _x, int _y) public view returns (bool) {
        uint locationId = LocationCoder.encodeLocationIdHM(_x, _y);
        uint tokenId = locationId2TokenId[locationId];
        return ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).exists(tokenId);
    }

    function ownerOfLand(int _x, int _y) public view returns (address) {
        uint locationId = LocationCoder.encodeLocationIdHM(_x, _y);
        uint tokenId = locationId2TokenId[locationId];
        return ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(tokenId);
    }

    function ownerOfLandMany(int[] _xs, int[] _ys) public view returns (address[]) {
        require(_xs.length > 0);
        require(_xs.length == _ys.length);

        address[] memory addrs = new address[](_xs.length);
        for (uint i = 0; i < _xs.length; i++) {
            addrs[i] = ownerOfLand(_xs[i], _ys[i]);
        }

        return addrs;
    }

    function landOf(address _landholder) public view returns (int[], int[]) {
        address objectOwnership = registry.addressOf(CONTRACT_OBJECT_OWNERSHIP);
        uint256 length = ERC721(objectOwnership).balanceOf(_landholder);
        int[] memory x = new int[](length);
        int[] memory y = new int[](length);

        ITokenLocation tokenLocation = ITokenLocation(registry.addressOf(CONTRACT_TOKEN_LOCATION));

        for(uint i = 0; i < length; i++) {
            uint tokenId = ERC721(objectOwnership).tokenOfOwnerByIndex(_landholder, i);
            (x[i], y[i]) = tokenLocation.getTokenLocationHM(tokenId);
        }

        return (x, y);
    }

    function isHasBox(uint256 _landTokenID) public view returns (bool) {
        return (tokenId2LandAttr[_landTokenID].mask & HASBOX) != 0;
    }

    function isReserved(uint256 _landTokenID) public view returns (bool) {
        return (tokenId2LandAttr[_landTokenID].mask & RESERVED) != 0;
    }

    function isSpecial(uint256 _landTokenID) public view returns (bool) {
        return (tokenId2LandAttr[_landTokenID].mask & SPECIAL) != 0;
    }

    function setHasBox(uint _landTokenID, bool _isHasBox) public auth {
        if (_isHasBox) {
            tokenId2LandAttr[_landTokenID].mask |= HASBOX;
        } else {
            tokenId2LandAttr[_landTokenID].mask &= ~HASBOX;
        }

        emit HasboxSetted(_landTokenID, _isHasBox);
    }

    function getResourceRateAttr(uint _landTokenId) public view returns (uint256) {
        return tokenId2LandAttr[_landTokenId].resourceRateAttr;
    }

    function setResourceRateAttr(uint _landTokenId, uint256 _newResourceRateAttr) public auth {
        tokenId2LandAttr[_landTokenId].resourceRateAttr = _newResourceRateAttr;

        emit ChangedReourceRateAttr(_landTokenId, _newResourceRateAttr);
    }

    function getFlagMask(uint _landTokenId) public view returns (uint256) {
        return tokenId2LandAttr[_landTokenId].mask;
    }

    function setFlagMask(uint _landTokenId, uint256 _newFlagMask) public auth {
        tokenId2LandAttr[_landTokenId].mask = _newFlagMask;
        emit ChangedFlagMask(_landTokenId, _newFlagMask);
    }

    function getResourceRate(uint _landTokenId, address _resourceToken) public view returns (uint16) {
        require(resourceToken2RateAttrId[_resourceToken] > 0, "Resource token doesn't exist.");

        uint moveRight = (16 * (resourceToken2RateAttrId[_resourceToken] - 1));
        return uint16((tokenId2LandAttr[_landTokenId].resourceRateAttr >> moveRight) & CLEAR_RATE_HIGH);
    }

    function setResourceRate(uint _landTokenId, address _resourceToken, uint16 _newResouceRate) public auth {
        require(resourceToken2RateAttrId[_resourceToken] > 0, "Reource token doesn't exist.");
        uint moveLeft = 16 * (resourceToken2RateAttrId[_resourceToken] - 1);
        tokenId2LandAttr[_landTokenId].resourceRateAttr &= (~(CLEAR_RATE_HIGH << moveLeft));
        tokenId2LandAttr[_landTokenId].resourceRateAttr |= (uint256(_newResouceRate) << moveLeft);
        emit ModifiedResourceRate(_landTokenId, _resourceToken, _newResouceRate);
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/token/interfaces/IERC20Token.sol

// pragma solidity ^0.4.23;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


// Dependency file: @evolutionland/bancor/solidity/contracts/utility/interfaces/IWhitelist.sol

// pragma solidity ^0.4.23;

/*
    Whitelist interface
*/
contract IWhitelist {
    function isWhitelisted(address _address) public view returns (bool);
}


// Dependency file: @evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorConverter.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IERC20Token.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/IWhitelist.sol';

/*
    Bancor Converter interface
*/
contract IBancorConverter {
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256);
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function conversionWhitelist() public view returns (IWhitelist) {}
    function conversionFee() public view returns (uint32) {}
    function connectors(address _address) public view returns (uint256, uint32, bool, bool, bool) {}
    function getConnectorBalance(IERC20Token _connectorToken) public view returns (uint256);
    function convertInternal(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function getPurchaseRequire(IERC20Token _connectorToken, uint256 _smartAmountToBuy, uint256 _errorSpace) public view returns (uint256);
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
}


// Dependency file: @evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorFormula.sol

// pragma solidity ^0.4.23;

/*
    Bancor Formula interface
*/
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256);
    function calculatePurchaseRequire(uint256 _connectorBalance, uint256 _supply, uint32 _connectorWeight, uint256 _buyAmount) public view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256);
    function calculateSaleRequire(uint256 _connectorBalance, uint256 _supply, uint32 _connectorWeight, uint256 _expectedSellReturn) public view returns (uint256);
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256);

}


// Dependency file: @evolutionland/bancor/solidity/contracts/IBancorNetwork.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IERC20Token.sol';

/*
    Bancor Network interface
*/
contract IBancorNetwork {
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256);
    function convertForPrioritized2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256);

    // deprecated, backward compatibility
    function convertForPrioritized(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256);
}


// Dependency file: @evolutionland/bancor/solidity/contracts/ContractIds.sol

// pragma solidity ^0.4.23;

/**
    Id definitions for bancor contracts

    Can be used in conjunction with the contract registry to get contract addresses
*/
contract ContractIds {
    // generic
    bytes32 public constant CONTRACT_FEATURES = "BancorContractFeatures";

    // bancor logic
    bytes32 public constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 public constant BANCOR_FORMULA = "BancorFormula";
    bytes32 public constant BANCOR_GAS_PRICE_LIMIT = "BancorGasPriceLimit";
    bytes32 public constant BANCOR_CONVERTER_FACTORY = "BancorConverterFactory";
}


// Dependency file: @evolutionland/bancor/solidity/contracts/FeatureIds.sol

// pragma solidity ^0.4.23;

/**
    Id definitions for bancor contract features

    Can be used to query the ContractFeatures contract to check whether a certain feature is supported by a contract
*/
contract FeatureIds {
    // converter features
    uint256 public constant CONVERTER_CONVERSION_WHITELIST = 1 << 0;
}


// Dependency file: @evolutionland/bancor/solidity/contracts/utility/Utils.sol

// pragma solidity ^0.4.23;

/*
    Utilities & Common Modifiers
*/
contract Utils {
    /**
        constructor
    */
    constructor() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/utility/interfaces/IContractFeatures.sol

// pragma solidity ^0.4.23;

/*
    Contract Features interface
*/
contract IContractFeatures {
    function isSupported(address _contract, uint256 _features) public view returns (bool);
    function enableFeatures(uint256 _features, bool _enable) public;
}


// Dependency file: @evolutionland/bancor/solidity/contracts/utility/interfaces/IOwned.sol

// pragma solidity ^0.4.23;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}


// Dependency file: @evolutionland/bancor/solidity/contracts/token/interfaces/ISmartToken.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IERC20Token.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/IOwned.sol';

/*
    Smart Token interface
*/
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}


// Dependency file: @evolutionland/bancor/solidity/contracts/utility/Owned.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/IOwned.sol';

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
        @dev constructor
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/utility/interfaces/ITokenHolder.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/IOwned.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IERC20Token.sol';

/*
    Token Holder interface
*/
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}


// Dependency file: @evolutionland/bancor/solidity/contracts/utility/TokenHolder.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Owned.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Utils.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/ITokenHolder.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IERC20Token.sol';

/*
    We consider every contract to be a 'token holder' since it's currently not possible
    for a contract to deny receiving tokens.

    The TokenHolder's contract sole purpose is to provide a safety mechanism that allows
    the owner to send tokens that were sent to the contract by mistake back to their sender.
*/
contract TokenHolder is ITokenHolder, Owned, Utils {
    /**
        @dev constructor
    */
    constructor() public {
    }

    /**
        @dev withdraws tokens held by the contract and sends them to an account
        can only be called by the owner

        @param _token   ERC20 token contract address
        @param _to      account to receive the new amount
        @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/token/SmartTokenController.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/ISmartToken.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/TokenHolder.sol';

/*
    The smart token controller is an upgradable part of the smart token that allows
    more functionality as well as fixes for bugs/exploits.
    Once it accepts ownership of the token, it becomes the token's sole controller
    that can execute any of its functions.

    To upgrade the controller, ownership must be transferred to a new controller, along with
    any relevant data.

    The smart token must be set on construction and cannot be changed afterwards.
    Wrappers are provided (as opposed to a single 'execute' function) for each of the token's functions, for easier access.

    Note that the controller can transfer token ownership to a new controller that
    doesn't allow executing any function on the token, for a trustless solution.
    Doing that will also remove the owner's ability to upgrade the controller.
*/
contract SmartTokenController is TokenHolder {
    ISmartToken public token;   // smart token

    /**
        @dev constructor
    */
    constructor(ISmartToken _token)
        public
        validAddress(_token)
    {
        token = _token;
    }

    // ensures that the controller is the token's owner
    modifier active() {
        assert(token.owner() == address(this));
        _;
    }

    // ensures that the controller is not the token's owner
    modifier inactive() {
        assert(token.owner() != address(this));
        _;
    }

    /**
        @dev allows transferring the token ownership
        the new owner still need to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new token owner
    */
    function transferTokenOwnership(address _newOwner) public ownerOnly {
        token.transferOwnership(_newOwner);
    }

    /**
        @dev used by a new owner to accept a token ownership transfer
        can only be called by the contract owner
    */
    function acceptTokenOwnership() public ownerOnly {
        token.acceptOwnership();
    }

    /**
        @dev disables/enables token transfers
        can only be called by the contract owner

        @param _disable    true to disable transfers, false to enable them
    */
    function disableTokenTransfers(bool _disable) public ownerOnly {
        token.disableTransfers(_disable);
    }

    /**
        @dev withdraws tokens held by the controller and sends them to an account
        can only be called by the owner

        @param _token   ERC20 token contract address
        @param _to      account to receive the new amount
        @param _amount  amount to withdraw
    */
    function withdrawFromToken(
        IERC20Token _token, 
        address _to, 
        uint256 _amount
    ) 
        public
        ownerOnly
    {
        ITokenHolder(token).withdrawTokens(_token, _to, _amount);
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/token/interfaces/IEtherToken.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IERC20Token.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/ITokenHolder.sol';

/*
    Ether Token interface
*/
contract IEtherToken is ITokenHolder, IERC20Token {
    function deposit() public payable;
    function withdraw(uint256 _amount) public;
    function withdrawTo(address _to, uint256 _amount) public;
}


// Dependency file: @evolutionland/bancor/solidity/contracts/converter/BancorConverter.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorConverter.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorFormula.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/IBancorNetwork.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/ContractIds.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/FeatureIds.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Utils.sol';
// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/IContractFeatures.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/SmartTokenController.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/ISmartToken.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IEtherToken.sol';

/*
    Bancor Converter v0.10

    The Bancor version of the token converter, allows conversion between a smart token and other ERC20 tokens and between different ERC20 tokens and themselves.

    ERC20 connector balance can be virtual, meaning that the calculations are based on the virtual balance instead of relying on
    the actual connector balance. This is a security mechanism that prevents the need to keep a very large (and valuable) balance in a single contract.

    The converter is upgradable (just like any SmartTokenController).

    WARNING: It is NOT RECOMMENDED to use the converter with Smart Tokens that have less than 8 decimal digits
             or with very small numbers because of precision loss

    Open issues:
    - Front-running attacks are currently mitigated by the following mechanisms:
        - minimum return argument for each conversion provides a way to define a minimum/maximum price for the transaction
        - gas price limit prevents users from having control over the order of execution
        - gas price limit check can be skipped if the transaction comes from a trusted, whitelisted signer
      Other potential solutions might include a commit/reveal based schemes
    - Possibly add getters for the connector fields so that the client won't need to rely on the order in the struct
*/
contract BancorConverter is IBancorConverter, SmartTokenController, ContractIds, FeatureIds {
    uint32 private constant MAX_WEIGHT = 1000000;
    uint64 private constant MAX_CONVERSION_FEE = 1000000;
    // 10 ** 7
    uint64 private constant MAX_ERROR_TOLERANT_BASE = 10000000;

    struct Connector {
        uint256 virtualBalance;         // connector virtual balance
        uint32 weight;                  // connector weight, represented in ppm, 1-1000000
        bool isVirtualBalanceEnabled;   // true if virtual balance is enabled, false if not
        bool isPurchaseEnabled;         // is purchase of the smart token enabled with the connector, can be set by the owner
        bool isSet;                     // used to tell if the mapping element is defined
    }

    string public version = '0.10';
    string public converterType = 'bancor';

    ISettingsRegistry public registry;                  // contract registry contract
    IWhitelist public conversionWhitelist;              // whitelist contract with list of addresses that are allowed to use the converter
    IERC20Token[] public connectorTokens;               // ERC20 standard token addresses
    IERC20Token[] public quickBuyPath;                  // conversion path that's used in order to buy the token with ETH
    mapping (address => Connector) public connectors;   // connector token addresses -> connector data
    uint32 private totalConnectorWeight = 0;            // used to efficiently prevent increasing the total connector weight above 100%
    uint32 public maxConversionFee = 0;                 // maximum conversion fee for the lifetime of the contract,
                                                        // represented in ppm, 0...1000000 (0 = no fee, 100 = 0.01%, 1000000 = 100%)
    uint32 public conversionFee = 0;                    // current conversion fee, represented in ppm, 0...maxConversionFee
    bool public conversionsEnabled = true;              // true if token conversions is enabled, false if not
    IERC20Token[] private convertPath;

    // triggered when a conversion between two tokens occurs
    event Conversion(
        address indexed _fromToken,
        address indexed _toToken,
        address indexed _trader,
        uint256 _amount,
        uint256 _return,
        int256 _conversionFee
    );
    // triggered after a conversion with new price data
    event PriceDataUpdate(
        address indexed _connectorToken,
        uint256 _tokenSupply,
        uint256 _connectorBalance,
        uint32 _connectorWeight
    );
    // triggered when the conversion fee is updated
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);

    /**
        @dev constructor

        @param  _token              smart token governed by the converter
        @param  _registry           address of a contract registry contract
        @param  _maxConversionFee   maximum conversion fee, represented in ppm
        @param  _connectorToken     optional, initial connector, allows defining the first connector at deployment time
        @param  _connectorWeight    optional, weight for the initial connector
    */
    constructor(
        ISmartToken _token,
        ISettingsRegistry _registry,
        uint32 _maxConversionFee,
        IERC20Token _connectorToken,
        uint32 _connectorWeight
    )
        public
        SmartTokenController(_token)
        validAddress(_registry)
        validMaxConversionFee(_maxConversionFee)
    {
        registry = _registry;
        IContractFeatures features = IContractFeatures(registry.addressOf(ContractIds.CONTRACT_FEATURES));

        // initialize supported features
        if (features != address(0))
            features.enableFeatures(CONVERTER_CONVERSION_WHITELIST, true);

        maxConversionFee = _maxConversionFee;

        if (_connectorToken != address(0))
            addConnector(_connectorToken, _connectorWeight, false);
    }

    // validates a connector token address - verifies that the address belongs to one of the connector tokens
    modifier validConnector(IERC20Token _address) {
        require(connectors[_address].isSet);
        _;
    }

    // validates a token address - verifies that the address belongs to one of the convertible tokens
    modifier validToken(IERC20Token _address) {
        require(_address == token || connectors[_address].isSet);
        _;
    }

    // validates maximum conversion fee
    modifier validMaxConversionFee(uint32 _conversionFee) {
        require(_conversionFee >= 0 && _conversionFee <= MAX_CONVERSION_FEE);
        _;
    }

    // validates conversion fee
    modifier validConversionFee(uint32 _conversionFee) {
        require(_conversionFee >= 0 && _conversionFee <= maxConversionFee);
        _;
    }

    // validates connector weight range
    modifier validConnectorWeight(uint32 _weight) {
        require(_weight > 0 && _weight <= MAX_WEIGHT);
        _;
    }

    // validates a conversion path - verifies that the number of elements is odd and that maximum number of 'hops' is 10
    modifier validConversionPath(IERC20Token[] _path) {
        require(_path.length > 2 && _path.length <= (1 + 2 * 10) && _path.length % 2 == 1);
        _;
    }

    // allows execution only when conversions aren't disabled
    modifier conversionsAllowed {
        assert(conversionsEnabled);
        _;
    }

    // allows execution by the BancorNetwork contract only
    modifier bancorNetworkOnly {
        IBancorNetwork bancorNetwork = IBancorNetwork(registry.addressOf(ContractIds.BANCOR_NETWORK));
        require(msg.sender == address(bancorNetwork));
        _;
    }

    /**
        @dev returns the number of connector tokens defined

        @return number of connector tokens
    */
    function connectorTokenCount() public view returns (uint16) {
        return uint16(connectorTokens.length);
    }

    /*
        @dev allows the owner to update the contract registry contract address

        @param _registry   address of a contract registry contract
    */
    function setRegistry(ISettingsRegistry _registry)
        public
        ownerOnly
        validAddress(_registry)
        notThis(_registry)
    {
        registry = _registry;
    }

    /*
        @dev allows the owner to update & enable the conversion whitelist contract address
        when set, only addresses that are whitelisted are actually allowed to use the converter
        note that the whitelist check is actually done by the BancorNetwork contract

        @param _whitelist    address of a whitelist contract
    */
    function setConversionWhitelist(IWhitelist _whitelist)
        public
        ownerOnly
        notThis(_whitelist)
    {
        conversionWhitelist = _whitelist;
    }

    /*
        @dev allows the owner to update the quick buy path

        @param _path    new quick buy path, see conversion path format in the bancorNetwork contract
    */
    function setQuickBuyPath(IERC20Token[] _path)
        public
        ownerOnly
        validConversionPath(_path)
    {
        quickBuyPath = _path;
    }

    /*
        @dev allows the owner to clear the quick buy path
    */
    function clearQuickBuyPath() public ownerOnly {
        quickBuyPath.length = 0;
    }

    /**
        @dev returns the length of the quick buy path array

        @return quick buy path length
    */
    function getQuickBuyPathLength() public view returns (uint256) {
        return quickBuyPath.length;
    }

    /**
        @dev disables the entire conversion functionality
        this is a safety mechanism in case of a emergency
        can only be called by the owner

        @param _disable true to disable conversions, false to re-enable them
    */
    function disableConversions(bool _disable) public ownerOnly {
        conversionsEnabled = !_disable;
    }

    /**
        @dev updates the current conversion fee
        can only be called by the owner

        @param _conversionFee new conversion fee, represented in ppm
    */
    function setConversionFee(uint32 _conversionFee)
        public
        ownerOnly
        validConversionFee(_conversionFee)
    {
        emit ConversionFeeUpdate(conversionFee, _conversionFee);
        conversionFee = _conversionFee;
    }

    /*
        @dev given a return amount, returns the amount minus the conversion fee

        @param _amount      return amount
        @param _magnitude   1 for standard conversion, 2 for cross connector conversion

        @return return amount minus conversion fee
    */
    function getFinalAmount(uint256 _amount, uint8 _magnitude) public view returns (uint256) {
        return safeMul(_amount, (MAX_CONVERSION_FEE - conversionFee) ** _magnitude) / MAX_CONVERSION_FEE ** _magnitude;
    }

    /**
        @dev defines a new connector for the token
        can only be called by the owner while the converter is inactive

        @param _token                  address of the connector token
        @param _weight                 constant connector weight, represented in ppm, 1-1000000
        @param _enableVirtualBalance   true to enable virtual balance for the connector, false to disable it
    */
    function addConnector(IERC20Token _token, uint32 _weight, bool _enableVirtualBalance)
        public
        ownerOnly
        inactive
        validAddress(_token)
        notThis(_token)
        validConnectorWeight(_weight)
    {
        require(_token != token && !connectors[_token].isSet && totalConnectorWeight + _weight <= MAX_WEIGHT); // validate input

        connectors[_token].virtualBalance = 0;
        connectors[_token].weight = _weight;
        connectors[_token].isVirtualBalanceEnabled = _enableVirtualBalance;
        connectors[_token].isPurchaseEnabled = true;
        connectors[_token].isSet = true;
        connectorTokens.push(_token);
        totalConnectorWeight += _weight;
    }

    /**
        @dev updates one of the token connectors
        can only be called by the owner

        @param _connectorToken         address of the connector token
        @param _weight                 constant connector weight, represented in ppm, 1-1000000
        @param _enableVirtualBalance   true to enable virtual balance for the connector, false to disable it
        @param _virtualBalance         new connector's virtual balance
    */
    function updateConnector(IERC20Token _connectorToken, uint32 _weight, bool _enableVirtualBalance, uint256 _virtualBalance)
        public
        ownerOnly
        validConnector(_connectorToken)
        validConnectorWeight(_weight)
    {
        Connector storage connector = connectors[_connectorToken];
        require(totalConnectorWeight - connector.weight + _weight <= MAX_WEIGHT); // validate input

        totalConnectorWeight = totalConnectorWeight - connector.weight + _weight;
        connector.weight = _weight;
        connector.isVirtualBalanceEnabled = _enableVirtualBalance;
        connector.virtualBalance = _virtualBalance;
    }

    /**
        @dev disables purchasing with the given connector token in case the connector token got compromised
        can only be called by the owner
        note that selling is still enabled regardless of this flag and it cannot be disabled by the owner

        @param _connectorToken  connector token contract address
        @param _disable         true to disable the token, false to re-enable it
    */
    function disableConnectorPurchases(IERC20Token _connectorToken, bool _disable)
        public
        ownerOnly
        validConnector(_connectorToken)
    {
        connectors[_connectorToken].isPurchaseEnabled = !_disable;
    }

    /**
        @dev returns the connector's virtual balance if one is defined, otherwise returns the actual balance

        @param _connectorToken  connector token contract address

        @return connector balance
    */
    function getConnectorBalance(IERC20Token _connectorToken)
        public
        view
        validConnector(_connectorToken)
        returns (uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        return connector.isVirtualBalanceEnabled ? connector.virtualBalance : _connectorToken.balanceOf(this);
    }

    /**
        @dev returns the expected return for converting a specific amount of _fromToken to _toToken

        @param _fromToken  ERC20 token to convert from
        @param _toToken    ERC20 token to convert to
        @param _amount     amount to convert, in fromToken

        @return expected conversion return amount
    */
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256) {
        require(_fromToken != _toToken); // validate input

        // conversion between the token and one of its connectors
        if (_toToken == token)
            return getPurchaseReturn(_fromToken, _amount);
        else if (_fromToken == token)
            return getSaleReturn(_toToken, _amount);

        // conversion between 2 connectors
        return getCrossConnectorReturn(_fromToken, _toToken, _amount);
    }

    /**
        @dev returns the expected return for buying the token for a connector token

        @param _connectorToken  connector token contract address
        @param _depositAmount   amount to deposit (in the connector token)

        @return expected purchase return amount
    */
    function getPurchaseReturn(IERC20Token _connectorToken, uint256 _depositAmount)
        public
        view
        active
        validConnector(_connectorToken)
        returns (uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        require(connector.isPurchaseEnabled); // validate input

        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));
        uint256 amount = formula.calculatePurchaseReturn(tokenSupply, connectorBalance, connector.weight, _depositAmount);

        // return the amount minus the conversion fee
        return getFinalAmount(amount, 1);
    }

    /**
            @dev returns the expected requirment connector token for buying the smart token

            @param _connectorToken  connector token contract address
            @param _smartAmountToBuy  amount to exchange for and buy (in the smart main token)
            @param _errorSpace error tolerant space for the return value

            @return expected purchase require amount
        */
    function getPurchaseRequire(IERC20Token _connectorToken, uint256 _smartAmountToBuy, uint256 _errorSpace)
        public
        view
        active
        validConnector(_connectorToken)
        returns (uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        require(connector.isPurchaseEnabled); // validate input

        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));
        uint256 amount = formula.calculatePurchaseRequire(connectorBalance, tokenSupply, connector.weight, _smartAmountToBuy);

        // return the amount minus the conversion fee
        return getFinalAmount(safeMul((amount + 1), (_errorSpace + MAX_ERROR_TOLERANT_BASE)) / MAX_ERROR_TOLERANT_BASE, 1);
    }


    /**
        @dev returns the expected return for selling the token for one of its connector tokens

        @param _connectorToken  connector token contract address
        @param _sellAmount      amount to sell (in the smart token)

        @return expected sale return amount
    */
    function getSaleReturn(IERC20Token _connectorToken, uint256 _sellAmount)
        public
        view
        active
        validConnector(_connectorToken)
        returns (uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));
        uint256 amount = formula.calculateSaleReturn(tokenSupply, connectorBalance, connector.weight, _sellAmount);

        // return the amount minus the conversion fee
        return getFinalAmount(amount, 1);
    }


    /**
       @dev returns the expected requirement smart token selling for a given amount of connector token

       @param _connectorToken  connector token contract address
       @param _connectorAmountToExchange  connector amount to exchange for (in the connector token)
       @param _errorSpace error tolerant space for the return value

       @return expected sale require amount

       NOTE: this not extremely precise. Use carefully.
   */
    function getSaleRequire(IERC20Token _connectorToken, uint256 _connectorAmountToExchange, uint _errorSpace)
    public
    view
    active
    validConnector(_connectorToken)
    returns (uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));
        uint256 amount = formula.calculateSaleRequire(tokenSupply, connectorBalance, connector.weight, _connectorAmountToExchange);

        // return the amount minus the conversion fee
        return getFinalAmount(safeMul(amount, (_errorSpace + MAX_ERROR_TOLERANT_BASE)) / MAX_ERROR_TOLERANT_BASE, 1);
    }

    /**
        @dev returns the expected return for selling one of the connector tokens for another connector token

        @param _fromConnectorToken  contract address of the connector token to convert from
        @param _toConnectorToken    contract address of the connector token to convert to
        @param _sellAmount          amount to sell (in the from connector token)

        @return expected sale return amount (in the to connector token)
    */
    function getCrossConnectorReturn(IERC20Token _fromConnectorToken, IERC20Token _toConnectorToken, uint256 _sellAmount)
        public
        view
        active
        validConnector(_fromConnectorToken)
        validConnector(_toConnectorToken)
        returns (uint256)
    {
        Connector storage fromConnector = connectors[_fromConnectorToken];
        Connector storage toConnector = connectors[_toConnectorToken];
        require(toConnector.isPurchaseEnabled); // validate input

        uint256 fromConnectorBalance = getConnectorBalance(_fromConnectorToken);
        uint256 toConnectorBalance = getConnectorBalance(_toConnectorToken);

        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));
        uint256 amount = formula.calculateCrossConnectorReturn(fromConnectorBalance, fromConnector.weight, toConnectorBalance, toConnector.weight, _sellAmount);

        // return the amount minus the conversion fee
        // the fee is higher (magnitude = 2) since cross connector conversion equals 2 conversions (from / to the smart token)
        return getFinalAmount(amount, 2);
    }

    /**
        @dev converts a specific amount of _fromToken to _toToken

        @param _fromToken  ERC20 token to convert from
        @param _toToken    ERC20 token to convert to
        @param _amount     amount to convert, in fromToken
        @param _minReturn  if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return conversion return amount
    */
    function convertInternal(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn)
        public
        bancorNetworkOnly
        conversionsAllowed
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(_fromToken != _toToken); // validate input

        // conversion between the token and one of its connectors
        if (_toToken == token)
            return buy(_fromToken, _amount, _minReturn);
        else if (_fromToken == token)
            return sell(_toToken, _amount, _minReturn);

        // conversion between 2 connectors
        uint256 amount = getCrossConnectorReturn(_fromToken, _toToken, _amount);
        // ensure the trade gives something in return and meets the minimum requested amount
        require(amount != 0 && amount >= _minReturn);

        // update the source token virtual balance if relevant
        Connector storage fromConnector = connectors[_fromToken];
        if (fromConnector.isVirtualBalanceEnabled)
            fromConnector.virtualBalance = safeAdd(fromConnector.virtualBalance, _amount);

        // update the target token virtual balance if relevant
        Connector storage toConnector = connectors[_toToken];
        if (toConnector.isVirtualBalanceEnabled)
            toConnector.virtualBalance = safeSub(toConnector.virtualBalance, amount);

        // ensure that the trade won't deplete the connector balance
        uint256 toConnectorBalance = getConnectorBalance(_toToken);
        assert(amount < toConnectorBalance);

        // transfer funds from the caller in the from connector token
        assert(_fromToken.transferFrom(msg.sender, this, _amount));
        // transfer funds to the caller in the to connector token
        // the transfer might fail if the actual connector balance is smaller than the virtual balance
        assert(_toToken.transfer(msg.sender, amount));

        // calculate conversion fee and dispatch the conversion event
        // the fee is higher (magnitude = 2) since cross connector conversion equals 2 conversions (from / to the smart token)
        uint256 feeAmount = safeSub(amount, getFinalAmount(amount, 2));
        dispatchConversionEvent(_fromToken, _toToken, _amount, amount, feeAmount);

        // dispatch price data updates for the smart token / both connectors
        emit PriceDataUpdate(_fromToken, token.totalSupply(), getConnectorBalance(_fromToken), fromConnector.weight);
        emit PriceDataUpdate(_toToken, token.totalSupply(), getConnectorBalance(_toToken), toConnector.weight);
        return amount;
    }

    /**
        @dev converts a specific amount of _fromToken to _toToken

        @param _fromToken  ERC20 token to convert from
        @param _toToken    ERC20 token to convert to
        @param _amount     amount to convert, in fromToken
        @param _minReturn  if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return conversion return amount
    */
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256) {
        convertPath = [_fromToken, token, _toToken];
        return quickConvert(convertPath, _amount, _minReturn);
    }

    /**
        @dev buys the token by depositing one of its connector tokens

        @param _connectorToken  connector token contract address
        @param _depositAmount   amount to deposit (in the connector token)
        @param _minReturn       if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return buy return amount
    */
    function buy(IERC20Token _connectorToken, uint256 _depositAmount, uint256 _minReturn) internal returns (uint256) {
        uint256 amount = getPurchaseReturn(_connectorToken, _depositAmount);
        // ensure the trade gives something in return and meets the minimum requested amount
        require(amount != 0 && amount >= _minReturn);

        // update virtual balance if relevant
        Connector storage connector = connectors[_connectorToken];
        if (connector.isVirtualBalanceEnabled)
            connector.virtualBalance = safeAdd(connector.virtualBalance, _depositAmount);

        // transfer funds from the caller in the connector token
        assert(_connectorToken.transferFrom(msg.sender, this, _depositAmount));
        // issue new funds to the caller in the smart token
        token.issue(msg.sender, amount);

        // calculate conversion fee and dispatch the conversion event
        uint256 feeAmount = safeSub(amount, getFinalAmount(amount, 1));
        dispatchConversionEvent(_connectorToken, token, _depositAmount, amount, feeAmount);

        // dispatch price data update for the smart token/connector
        emit PriceDataUpdate(_connectorToken, token.totalSupply(), getConnectorBalance(_connectorToken), connector.weight);
        return amount;
    }

    /**
        @dev sells the token by withdrawing from one of its connector tokens

        @param _connectorToken  connector token contract address
        @param _sellAmount      amount to sell (in the smart token)
        @param _minReturn       if the conversion results in an amount smaller the minimum return - it is cancelled, must be nonzero

        @return sell return amount
    */
    function sell(IERC20Token _connectorToken, uint256 _sellAmount, uint256 _minReturn) internal returns (uint256) {
        require(_sellAmount <= token.balanceOf(msg.sender)); // validate input

        uint256 amount = getSaleReturn(_connectorToken, _sellAmount);
        // ensure the trade gives something in return and meets the minimum requested amount
        require(amount != 0 && amount >= _minReturn);

        // ensure that the trade will only deplete the connector balance if the total supply is depleted as well
        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        assert(amount < connectorBalance || (amount == connectorBalance && _sellAmount == tokenSupply));

        // update virtual balance if relevant
        Connector storage connector = connectors[_connectorToken];
        if (connector.isVirtualBalanceEnabled)
            connector.virtualBalance = safeSub(connector.virtualBalance, amount);

        // destroy _sellAmount from the caller's balance in the smart token
        token.destroy(msg.sender, _sellAmount);
        // transfer funds to the caller in the connector token
        // the transfer might fail if the actual connector balance is smaller than the virtual balance
        assert(_connectorToken.transfer(msg.sender, amount));

        // calculate conversion fee and dispatch the conversion event
        uint256 feeAmount = safeSub(amount, getFinalAmount(amount, 1));
        dispatchConversionEvent(token, _connectorToken, _sellAmount, amount, feeAmount);

        // dispatch price data update for the smart token/connector
        emit PriceDataUpdate(_connectorToken, token.totalSupply(), getConnectorBalance(_connectorToken), connector.weight);
        return amount;
    }

    /**
        @dev converts the token to any other token in the bancor network by following a predefined conversion path
        note that when converting from an ERC20 token (as opposed to a smart token), allowance must be set beforehand

        @param _path        conversion path, see conversion path format in the BancorNetwork contract
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return tokens issued in return
    */
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn)
        public
        payable
        validConversionPath(_path)
        returns (uint256)
    {
        return quickConvertPrioritized(_path, _amount, _minReturn, 0x0, 0x0, 0x0, 0x0);
    }

    /**
        @dev converts the token to any other token in the bancor network by following a predefined conversion path
        note that when converting from an ERC20 token (as opposed to a smart token), allowance must be set beforehand

        @param _path        conversion path, see conversion path format in the BancorNetwork contract
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
        @param _block       if the current block exceeded the given parameter - it is cancelled
        @param _v           (signature[128:130]) associated with the signer address and helps validating if the signature is legit
        @param _r           (signature[0:64]) associated with the signer address and helps validating if the signature is legit
        @param _s           (signature[64:128]) associated with the signer address and helps validating if the signature is legit

        @return tokens issued in return
    */
    function quickConvertPrioritized(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, uint256 _block, uint8 _v, bytes32 _r, bytes32 _s)
        public
        payable
        validConversionPath(_path)
        returns (uint256)
    {
        IERC20Token fromToken = _path[0];
        IBancorNetwork bancorNetwork = IBancorNetwork(registry.addressOf(ContractIds.BANCOR_NETWORK));

        // we need to transfer the source tokens from the caller to the BancorNetwork contract,
        // so it can execute the conversion on behalf of the caller
        if (msg.value == 0) {
            // not ETH, send the source tokens to the BancorNetwork contract
            // if the token is the smart token, no allowance is required - destroy the tokens
            // from the caller and issue them to the BancorNetwork contract
            if (fromToken == token) {
                token.destroy(msg.sender, _amount); // destroy _amount tokens from the caller's balance in the smart token
                token.issue(bancorNetwork, _amount); // issue _amount new tokens to the BancorNetwork contract
            } else {
                // otherwise, we assume we already have allowance, transfer the tokens directly to the BancorNetwork contract
                assert(fromToken.transferFrom(msg.sender, bancorNetwork, _amount));
            }
        }

        // execute the conversion and pass on the ETH with the call
        return bancorNetwork.convertForPrioritized2.value(msg.value)(_path, _amount, _minReturn, msg.sender, _block, _v, _r, _s);
    }

    /**
        @dev helper, dispatches the Conversion event

        @param _fromToken       ERC20 token to convert from
        @param _toToken         ERC20 token to convert to
        @param _amount          amount purchased/sold (in the source token)
        @param _returnAmount    amount returned (in the target token)
    */
    function dispatchConversionEvent(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _returnAmount, uint256 _feeAmount) private {
        // fee amount is converted to 255 bits -
        // negative amount means the fee is taken from the source token, positive amount means its taken from the target token
        // currently the fee is always taken from the target token
        // since we convert it to a signed number, we first ensure that it's capped at 255 bits to prevent overflow
        assert(_feeAmount <= 2 ** 255);
        emit Conversion(_fromToken, _toToken, msg.sender, _amount, _returnAmount, int256(_feeAmount));
    }

    /**
        @dev fallback, buys the smart token with ETH
        note that the purchase will use the price at the time of the purchase
    */
    function() payable public {
        quickConvert(quickBuyPath, msg.value, 1);
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/converter/BancorFormula.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorFormula.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Utils.sol';

contract BancorFormula is IBancorFormula, Utils {
    string public version = '0.3';

    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    /**
        Auto-generated via 'PrintIntScalingFactors.py'
    */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    /**
        Auto-generated via 'PrintLn2ScalingFactors.py'
    */
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
        Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    */
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    /**
        Auto-generated via 'PrintFunctionBancorFormula.py'
    */
    uint256[128] private maxExpArray;
    constructor() public {
    //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
    //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
    //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
    //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
    //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
    //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
    //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
    //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
    //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
    //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
    //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
    //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
    //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
    //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
    //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
    //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
    //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
    //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
    //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
    //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
    //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
    //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
    //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
    //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
    //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
    //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
    //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
    //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
    //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
    //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
    //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
    //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[ 32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[ 33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[ 34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[ 35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[ 36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[ 37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[ 38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[ 39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[ 40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[ 41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[ 42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[ 43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[ 44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[ 45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[ 46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[ 47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[ 48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[ 49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[ 50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[ 51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[ 52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[ 53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[ 54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[ 55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[ 56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[ 57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[ 58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[ 59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[ 60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[ 61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[ 62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[ 63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[ 64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[ 65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[ 66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[ 67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[ 68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[ 69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[ 70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[ 71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[ 72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[ 73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[ 74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[ 75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[ 76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[ 77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[ 78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[ 79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[ 80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[ 81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[ 82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[ 83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[ 84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[ 85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[ 86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[ 87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[ 88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[ 89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[ 90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[ 91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[ 92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[ 93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[ 94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[ 95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[ 96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[ 97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[ 98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[ 99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    /**
        @dev given a token supply, connector balance, weight and a deposit amount (in the connector token),
        calculates the return for a given conversion (in the main token)

        Formula:
        Return = _supply * ((1 + _depositAmount / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)

        @param _supply              token total supply
        @param _connectorBalance    total connector balance
        @param _connectorWeight     connector weight, represented in ppm, 1-1000000
        @param _depositAmount       deposit amount, in connector token

        @return purchase return amount
    */
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256) {
        // validate input
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT);

        // special case for 0 deposit amount
        if (_depositAmount == 0)
            return 0;

        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_supply, _depositAmount) / _connectorBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = safeAdd(_depositAmount, _connectorBalance);
        (result, precision) = power(baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT);
        uint256 temp = safeMul(_supply, result) >> precision;
        return temp - _supply;
    }

    /**
        @dev given a token supply, connector balance, weight and a sell amount (in the main token),
        calculates the return for a given conversion (in the connector token)

        Formula:
        Return = _connectorBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_connectorWeight / 1000000)))

        @param _supply              token total supply
        @param _connectorBalance    total connector
        @param _connectorWeight     constant connector Weight, represented in ppm, 1-1000000
        @param _sellAmount          sell amount, in the token itself

        @return sale return amount
    */
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256) {
        // validate input
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT && _sellAmount <= _supply);

        // special case for 0 sell amount
        if (_sellAmount == 0)
            return 0;

        // special case for selling the entire supply
        if (_sellAmount == _supply)
            return _connectorBalance;

        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_connectorBalance, _sellAmount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _connectorWeight);
        uint256 temp1 = safeMul(_connectorBalance, result);
        uint256 temp2 = _connectorBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
        @dev given two connector balances/weights and a sell amount (in the first connector token),
        calculates the return for a conversion from the first connector token to the second connector token (in the second connector token)

        Formula:
        Return = _toConnectorBalance * (1 - (_fromConnectorBalance / (_fromConnectorBalance + _amount)) ^ (_fromConnectorWeight / _toConnectorWeight))

        @param _fromConnectorBalance    input connector balance
        @param _fromConnectorWeight     input connector weight, represented in ppm, 1-1000000
        @param _toConnectorBalance      output connector balance
        @param _toConnectorWeight       output connector weight, represented in ppm, 1-1000000
        @param _amount                  input connector amount

        @return second connector amount
    */
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256) {
        // validate input
        require(_fromConnectorBalance > 0 && _fromConnectorWeight > 0 && _fromConnectorWeight <= MAX_WEIGHT && _toConnectorBalance > 0 && _toConnectorWeight > 0 && _toConnectorWeight <= MAX_WEIGHT);

        // special case for equal weights
        if (_fromConnectorWeight == _toConnectorWeight)
            return safeMul(_toConnectorBalance, _amount) / safeAdd(_fromConnectorBalance, _amount);

        uint256 result;
        uint8 precision;
        uint256 baseN = safeAdd(_fromConnectorBalance, _amount);
        (result, precision) = power(baseN, _fromConnectorBalance, _fromConnectorWeight, _toConnectorWeight);
        uint256 temp1 = safeMul(_toConnectorBalance, result);
        uint256 temp2 = _toConnectorBalance << precision;
        return (temp1 - temp2) / result;
    }

    /**
        General Description:
            Determine a value of precision.
            Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
            Return the result along with the precision used.

        Detailed Description:
            Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
            The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
            The larger "precision" is, the more accurately this value represents the real value.
            However, the larger "precision" is, the more bits are required in order to store this value.
            And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
            This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
            Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
            This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
            This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
    */
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal view returns (uint256, uint8) {
        assert(_baseN < MAX_NUM);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        }
        else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = baseLog * _expN / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        }
        else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

    /**
        Compute log(x / FIXED_1) * FIXED_1.
        This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
    */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }

    /**
        Compute the largest integer smaller than or equal to the binary logarithm of the input.
    */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        }
        else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
        The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
        - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
        - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
    */
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x)
                lo = mid;
            else
                hi = mid;
        }

        if (maxExpArray[hi] >= _x)
            return hi;
        if (maxExpArray[lo] >= _x)
            return lo;

        assert(false);
        return 0;
    }

    /**
        This function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
        It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
        It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
        The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
        The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
    */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision; res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision; res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision; res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision; res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision; res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision; res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
        Return log(x / FIXED_1) * FIXED_1
        Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalLog.py'
    */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {res += 0x40000000000000000000000000000000; x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd8;}
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {res += 0x20000000000000000000000000000000; x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a7;}
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {res += 0x10000000000000000000000000000000; x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a1;}
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {res += 0x08000000000000000000000000000000; x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a8;}
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {res += 0x04000000000000000000000000000000; x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd3;}
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {res += 0x02000000000000000000000000000000; x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a2;}
        if (x >= 0x810100ab00222d861931c15e39b44e99) {res += 0x01000000000000000000000000000000; x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e99;}
        if (x >= 0x808040155aabbbe9451521693554f733) {res += 0x00800000000000000000000000000000; x = x * FIXED_1 / 0x808040155aabbbe9451521693554f733;}

        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1;
        res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;

        return res;
    }

    /**
        Return e ^ (x / FIXED_1) * FIXED_1
        Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalExp.py'
    */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000;
        z = z * y / FIXED_1; res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_1; res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_1; res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_1; res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_1; res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_1; res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_1; res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_1; res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_1; res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_1; res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_1; res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_1; res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_1; res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_1; res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_1; res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_1; res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_1; res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_1; res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_1; res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0) res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776;
        if ((x & 0x020000000000000000000000000000000) != 0) res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4;
        if ((x & 0x040000000000000000000000000000000) != 0) res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f;
        if ((x & 0x080000000000000000000000000000000) != 0) res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9;
        if ((x & 0x100000000000000000000000000000000) != 0) res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea;
        if ((x & 0x200000000000000000000000000000000) != 0) res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d;
        if ((x & 0x400000000000000000000000000000000) != 0) res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11;

        return res;
    }


    /**
        @dev given a token supply, connector balance, weight and and a sell amount (in the main token),
        calculates the return for a given conversion (in the connector token)

        Formula:
        Return = _connectorBalance * ((1 + _sellAmount / _supply) ^ (1/(_connectorWeight / 1000000)) - 1)

        @param _supply              token total supply
        @param _connectorBalance    total connector balance
        @param _connectorWeight     connector weight, represented in ppm, 1-1000000
        @param _buyAmount           buy amount, in the main token

        @return purchase require amount
    */
    function calculatePurchaseRequire(uint256 _connectorBalance, uint256 _supply, uint32 _connectorWeight, uint256 _buyAmount) public view returns (uint256) {
        // validate input
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT);

        // special case for 0 deposit amount
        if (_buyAmount == 0)
            return 0;

        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_connectorBalance, _buyAmount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseN = safeAdd(_buyAmount, _supply);
        (result, precision) = power(baseN, _supply, MAX_WEIGHT, _connectorWeight);
        uint256 temp = safeMul(_connectorBalance, result) >> precision;
        return temp - _connectorBalance;
    }

    /**
        @dev given a token supply, connector balance, weight and a sell amount (in the connector token),
        calculates the return for a given conversion (in the main token)

        Formula:
        Return = _supply * (1 - (1 - _sellAmount / _connectorBalance) ^ (_connectorWeight / 1000000))

        @param _connectorBalance    total connector
        @param _supply              token total supply
        @param _connectorWeight     constant connector Weight, represented in ppm, 1-1000000
        @param _expectedSellReturn  expected sell return, in the connector token

        @return sale return amount
    */
    function calculateSaleRequire(uint256 _connectorBalance, uint256 _supply, uint32 _connectorWeight, uint256 _expectedSellReturn) public view returns (uint256) {
        // validate input
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT && _expectedSellReturn <= _connectorBalance);

        // special case for 0 sell amount
        if (_expectedSellReturn == 0)
            return 0;

        // special case for selling the entire supply
        if (_expectedSellReturn == _connectorBalance)
            return _supply;

        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_supply, _expectedSellReturn) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _connectorBalance - _expectedSellReturn;
        (result, precision) = power(_connectorBalance, baseD, _connectorWeight, MAX_WEIGHT);
        uint256 temp1 = safeMul(_supply, result);
        uint256 temp2 = _supply << precision;
        return (temp1 - temp2) / result;
    }

}


// Dependency file: @evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorGasPriceLimit.sol

// pragma solidity ^0.4.23;

/*
    Bancor Gas Price Limit interface
*/
contract IBancorGasPriceLimit {
    function gasPrice() public view returns (uint256) {}
    function validateGasPrice(uint256) public view;
}


// Dependency file: @evolutionland/bancor/solidity/contracts/converter/BancorGasPriceLimit.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorGasPriceLimit.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Owned.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Utils.sol';

/*
    The BancorGasPriceLimit contract serves as an extra front-running attack mitigation mechanism.
    It sets a maximum gas price on all bancor conversions, which prevents users from "cutting in line"
    in order to front-run other transactions.
    The gas price limit is universal to all converters and it can be updated by the owner to be in line
    with the network's current gas price.
*/
contract BancorGasPriceLimit is IBancorGasPriceLimit, Owned, Utils {
    uint256 public gasPrice = 0 wei;    // maximum gas price for bancor transactions
    
    /**
        @dev constructor

        @param _gasPrice    gas price limit
    */
    constructor(uint256 _gasPrice)
        public
        greaterThanZero(_gasPrice)
    {
        gasPrice = _gasPrice;
    }

    /*
        @dev allows the owner to update the gas price limit

        @param _gasPrice    new gas price limit
    */
    function setGasPrice(uint256 _gasPrice)
        public
        ownerOnly
        greaterThanZero(_gasPrice)
    {
        gasPrice = _gasPrice;
    }

    /*
        @dev validate that the given gas price is equal to the current network gas price

        @param _gasPrice    tested gas price
    */
    function validateGasPrice(uint256 _gasPrice)
        public
        view
        greaterThanZero(_gasPrice)
    {
        require(_gasPrice <= gasPrice);
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/token/ERC20Token.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IERC20Token.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Utils.sol';

/**
    ERC20 Standard Token implementation
*/
contract ERC20Token is IERC20Token, Utils {
    string public standard = 'Token 0.1';
    string public name = '';
    string public symbol = '';
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
        @dev constructor

        @param _name        token name
        @param _symbol      token symbol
        @param _decimals    decimal points, for display purposes
    */
    constructor(string _name, string _symbol, uint8 _decimals) public {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
        @dev allow another account/contract to spend some tokens on your behalf
        throws on any error rather then return a false flag to minimize user errors

        also, to minimize the risk of the approve/transferFrom attack vector
        (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
        in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value

        @param _spender approved address
        @param _value   allowance amount

        @return true if the approval was successful, false if it wasn't
    */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/token/EtherToken.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/ERC20Token.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IEtherToken.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Owned.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/TokenHolder.sol';

/**
    Ether tokenization contract

    'Owned' is specified here for readability reasons
*/
contract EtherToken is IEtherToken, Owned, ERC20Token, TokenHolder {
    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);

    /**
        @dev constructor
    */
    constructor()
        public
        ERC20Token('Ether Token', 'ETH', 18) {
    }

    /**
        @dev deposit ether in the account
    */
    function deposit() public payable {
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], msg.value); // add the value to the account balance
        totalSupply = safeAdd(totalSupply, msg.value); // increase the total supply

        emit Issuance(msg.value);
        emit Transfer(this, msg.sender, msg.value);
    }

    /**
        @dev withdraw ether from the account

        @param _amount  amount of ether to withdraw
    */
    function withdraw(uint256 _amount) public {
        withdrawTo(msg.sender, _amount);
    }

    /**
        @dev withdraw ether from the account to a target account

        @param _to      account to receive the ether
        @param _amount  amount of ether to withdraw
    */
    function withdrawTo(address _to, uint256 _amount)
        public
        notThis(_to)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _amount); // deduct the amount from the account balance
        totalSupply = safeSub(totalSupply, _amount); // decrease the total supply
        _to.transfer(_amount); // send the amount to the target account

        emit Transfer(msg.sender, this, _amount);
        emit Destruction(_amount);
    }

    // ERC20 standard method overrides with some extra protection

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        notThis(_to)
        returns (bool success)
    {
        assert(super.transfer(_to, _value));
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        notThis(_to)
        returns (bool success)
    {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }

    /**
        @dev deposit ether in the account
    */
    function() public payable {
        deposit();
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/utility/ContractFeatures.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/IContractFeatures.sol';

/**
    Contract Features

    Generic contract that allows every contract on the blockchain to define which features it supports.
    Other contracts can query this contract to find out whether a given contract on the
    blockchain supports a certain feature.
    Each contract type can define its own list of feature flags.
    Features can be only enabled/disabled by the contract they are defined for.

    Features should be defined by each contract type as bit flags, e.g. -
    uint256 public constant FEATURE1 = 1 << 0;
    uint256 public constant FEATURE2 = 1 << 1;
    uint256 public constant FEATURE3 = 1 << 2;
    ...
*/
contract ContractFeatures is IContractFeatures {
    mapping (address => uint256) private featureFlags;

    event FeaturesAddition(address indexed _address, uint256 _features);
    event FeaturesRemoval(address indexed _address, uint256 _features);

    /**
        @dev constructor
    */
    constructor() public {
    }

    /**
        @dev returns true if a given contract supports the given feature(s), false if not

        @param _contract    contract address to check support for
        @param _features    feature(s) to check for

        @return true if the contract supports the feature(s), false if not
    */
    function isSupported(address _contract, uint256 _features) public view returns (bool) {
        return (featureFlags[_contract] & _features) == _features;
    }

    /**
        @dev allows a contract to enable/disable certain feature(s)

        @param _features    feature(s) to enable/disable
        @param _enable      true to enable the feature(s), false to disabled them
    */
    function enableFeatures(uint256 _features, bool _enable) public {
        if (_enable) {
            if (isSupported(msg.sender, _features))
                return;

            featureFlags[msg.sender] |= _features;

            emit FeaturesAddition(msg.sender, _features);
        } else {
            if (!isSupported(msg.sender, _features))
                return;

            featureFlags[msg.sender] &= ~_features;

            emit FeaturesRemoval(msg.sender, _features);
        }
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/utility/Whitelist.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Owned.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/Utils.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/IWhitelist.sol';

/**
    Whitelist

    The contract manages a list of whitelisted addresses
*/
contract Whitelist is IWhitelist, Owned, Utils {
    mapping (address => bool) private whitelist;

    event AddressAddition(address _address);
    event AddressRemoval(address _address);

    /**
        @dev constructor
    */
    constructor() public {
    }

    // allows execution by a whitelisted address only
    modifier whitelistedOnly() {
        require(whitelist[msg.sender]);
        _;
    }

    /**
        @dev returns true if a given address is whitelisted, false if not

        @param _address address to check

        @return true if the address is whitelisted, false if not
    */
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    /**
        @dev adds a given address to the whitelist

        @param _address address to add
    */
    function addAddress(address _address)
        ownerOnly
        validAddress(_address)
        public 
    {
        if (whitelist[_address]) // checks if the address is already whitelisted
            return;

        whitelist[_address] = true;
        emit AddressAddition(_address);
    }

    /**
        @dev adds a list of addresses to the whitelist

        @param _addresses addresses to add
    */
    function addAddresses(address[] _addresses) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addAddress(_addresses[i]);
        }
    }

    /**
        @dev removes a given address from the whitelist

        @param _address address to remove
    */
    function removeAddress(address _address) ownerOnly public {
        if (!whitelist[_address]) // checks if the address is actually whitelisted
            return;

        whitelist[_address] = false;
        emit AddressRemoval(_address);
    }

    /**
        @dev removes a list of addresses from the whitelist

        @param _addresses addresses to remove
    */
    function removeAddresses(address[] _addresses) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            removeAddress(_addresses[i]);
        }
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/BancorNetwork.sol

// pragma solidity ^0.4.23;
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/IBancorNetwork.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/ContractIds.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/FeatureIds.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorConverter.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorFormula.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorGasPriceLimit.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/TokenHolder.sol';
// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/IContractFeatures.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/utility/interfaces/IWhitelist.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/IEtherToken.sol';
// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/bancor/solidity/contracts/token/interfaces/ISmartToken.sol';

/*
    The BancorNetwork contract is the main entry point for bancor token conversions.
    It also allows converting between any token in the bancor network to any other token
    in a single transaction by providing a conversion path.

    A note on conversion path -
    Conversion path is a data structure that's used when converting a token to another token in the bancor network
    when the conversion cannot necessarily be done by single converter and might require multiple 'hops'.
    The path defines which converters should be used and what kind of conversion should be done in each step.

    The path format doesn't include complex structure and instead, it is represented by a single array
    in which each 'hop' is represented by a 2-tuple - smart token & to token.
    In addition, the first element is always the source token.
    The smart token is only used as a pointer to a converter (since converter addresses are more likely to change).

    Format:
    [source token, smart token, to token, smart token, to token...]
*/
contract BancorNetwork is IBancorNetwork, TokenHolder, ContractIds, FeatureIds {
    uint64 private constant MAX_CONVERSION_FEE = 1000000;

    address public signerAddress = 0x0;         // verified address that allows conversions with higher gas price
    ISettingsRegistry public registry;          // contract registry contract address

    mapping (address => bool) public etherTokens;       // list of all supported ether tokens
    mapping (bytes32 => bool) public conversionHashes;  // list of conversion hashes, to prevent re-use of the same hash

    /**
        @dev constructor

        @param _registry    address of a contract registry contract
    */
    constructor(ISettingsRegistry _registry) public validAddress(_registry) {
        registry = _registry;
    }

    // validates a conversion path - verifies that the number of elements is odd and that maximum number of 'hops' is 10
    modifier validConversionPath(IERC20Token[] _path) {
        require(_path.length > 2 && _path.length <= (1 + 2 * 10) && _path.length % 2 == 1);
        _;
    }

    /*
        @dev allows the owner to update the contract registry contract address

        @param _registry   address of a contract registry contract
    */
    function setRegistry(ISettingsRegistry _registry)
        public
        ownerOnly
        validAddress(_registry)
        notThis(_registry)
    {
        registry = _registry;
    }

    /*
        @dev allows the owner to update the signer address

        @param _signerAddress    new signer address
    */
    function setSignerAddress(address _signerAddress)
        public
        ownerOnly
        validAddress(_signerAddress)
        notThis(_signerAddress)
    {
        signerAddress = _signerAddress;
    }

    /**
        @dev allows the owner to register/unregister ether tokens

        @param _token       ether token contract address
        @param _register    true to register, false to unregister
    */
    function registerEtherToken(IEtherToken _token, bool _register)
        public
        ownerOnly
        validAddress(_token)
        notThis(_token)
    {
        etherTokens[_token] = _register;
    }

    /**
        @dev verifies that the signer address is trusted by recovering 
        the address associated with the public key from elliptic 
        curve signature, returns zero on error.
        notice that the signature is valid only for one conversion
        and expires after the give block.

        @return true if the signer is verified
    */
    function verifyTrustedSender(IERC20Token[] _path, uint256 _amount, uint256 _block, address _addr, uint8 _v, bytes32 _r, bytes32 _s) private returns(bool) {
        bytes32 hash = keccak256(_block, tx.gasprice, _addr, msg.sender, _amount, _path);

        // checking that it is the first conversion with the given signature
        // and that the current block number doesn't exceeded the maximum block
        // number that's allowed with the current signature
        require(!conversionHashes[hash] && block.number <= _block);

        // recovering the signing address and comparing it to the trusted signer
        // address that was set in the contract
        bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n32", hash);
        bool verified = ecrecover(prefixedHash, _v, _r, _s) == signerAddress;

        // if the signer is the trusted signer - mark the hash so that it can't
        // be used multiple times
        if (verified)
            conversionHashes[hash] = true;
        return verified;
    }

    /**
        @dev converts the token to any other token in the bancor network by following
        a predefined conversion path and transfers the result tokens to a target account
        note that the converter should already own the source tokens

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
        @param _for         account that will receive the conversion result

        @return tokens issued in return
    */
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256) {
        return convertForPrioritized2(_path, _amount, _minReturn, _for, 0x0, 0x0, 0x0, 0x0);
    }

    /**
        @dev converts the token to any other token in the bancor network
        by following a predefined conversion path and transfers the result
        tokens to a target account.
        this version of the function also allows the verified signer
        to bypass the universal gas price limit.
        note that the converter should already own the source tokens

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
        @param _for         account that will receive the conversion result

        @return tokens issued in return
    */
    function convertForPrioritized2(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for, uint256 _block, uint8 _v, bytes32 _r, bytes32 _s)
        public
        payable
        validConversionPath(_path)
        returns (uint256)
    {
        // if ETH is provided, ensure that the amount is identical to _amount and verify that the source token is an ether token
        IERC20Token fromToken = _path[0];
        require(msg.value == 0 || (_amount == msg.value && etherTokens[fromToken]));

        // if ETH was sent with the call, the source is an ether token - deposit the ETH in it
        // otherwise, we assume we already have the tokens
        if (msg.value > 0)
            IEtherToken(fromToken).deposit.value(msg.value)();

        return convertForInternal(_path, _amount, _minReturn, _for, _block, _v, _r, _s);
    }

    /**
        @dev converts token to any other token in the bancor network
        by following the predefined conversion paths and transfers the result
        tokens to a targeted account.
        this version of the function also allows multiple conversions
        in a single atomic transaction.
        note that the converter should already own the source tokens

        @param _paths           merged conversion paths, i.e. [path1, path2, ...]. see conversion path format above
        @param _pathStartIndex  each item in the array is the start index of the nth path in _paths
        @param _amounts         amount to convert from (in the initial source token) for each path
        @param _minReturns      minimum return for each path. if the conversion results in an amount 
                                smaller than the minimum return - it is cancelled, must be nonzero
        @param _for             account that will receive the conversions result

        @return amount of conversion result for each path
    */
    function convertForMultiple(IERC20Token[] _paths, uint256[] _pathStartIndex, uint256[] _amounts, uint256[] _minReturns, address _for)
        public
        payable
        returns (uint256[])
    {
        // if ETH is provided, ensure that the total amount was converted into other tokens
        uint256 convertedValue = 0;
        uint256 pathEndIndex;
        
        // iterate over the conversion paths
        for (uint256 i = 0; i < _pathStartIndex.length; i += 1) {
            pathEndIndex = i == (_pathStartIndex.length - 1) ? _paths.length : _pathStartIndex[i + 1];

            // copy a single path from _paths into an array
            IERC20Token[] memory path = new IERC20Token[](pathEndIndex - _pathStartIndex[i]);
            for (uint256 j = _pathStartIndex[i]; j < pathEndIndex; j += 1) {
                path[j - _pathStartIndex[i]] = _paths[j];
            }

            // if ETH is provided, ensure that the amount is lower than the path amount and
            // verify that the source token is an ether token. otherwise ensure that 
            // the source is not an ether token
            IERC20Token fromToken = path[0];
            require(msg.value == 0 || (_amounts[i] <= msg.value && etherTokens[fromToken]) || !etherTokens[fromToken]);

            // if ETH was sent with the call, the source is an ether token - deposit the ETH path amount in it.
            // otherwise, we assume we already have the tokens
            if (msg.value > 0 && etherTokens[fromToken]) {
                IEtherToken(fromToken).deposit.value(_amounts[i])();
                convertedValue += _amounts[i];
            }
            _amounts[i] = convertForInternal(path, _amounts[i], _minReturns[i], _for, 0x0, 0x0, 0x0, 0x0);
        }

        // if ETH was provided, ensure that the full amount was converted
        require(convertedValue == msg.value);

        return _amounts;
    }

    /**
        @dev converts token to any other token in the bancor network
        by following a predefined conversion paths and transfers the result
        tokens to a target account.

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
        @param _for         account that will receive the conversion result
        @param _block       if the current block exceeded the given parameter - it is cancelled
        @param _v           (signature[128:130]) associated with the signer address and helps to validate if the signature is legit
        @param _r           (signature[0:64]) associated with the signer address and helps to validate if the signature is legit
        @param _s           (signature[64:128]) associated with the signer address and helps to validate if the signature is legit

        @return tokens issued in return
    */
    function convertForInternal(
        IERC20Token[] _path, 
        uint256 _amount, 
        uint256 _minReturn, 
        address _for, 
        uint256 _block, 
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s
    )
        private
        validConversionPath(_path)
        returns (uint256)
    {
        if (_v == 0x0 && _r == 0x0 && _s == 0x0) {
            IBancorGasPriceLimit gasPriceLimit = IBancorGasPriceLimit(registry.addressOf(ContractIds.BANCOR_GAS_PRICE_LIMIT));
            gasPriceLimit.validateGasPrice(tx.gasprice);
        }
        else {
            require(verifyTrustedSender(_path, _amount, _block, _for, _v, _r, _s));
        }

        // if ETH is provided, ensure that the amount is identical to _amount and verify that the source token is an ether token
        IERC20Token fromToken = _path[0];

        IERC20Token toToken;
        
        (toToken, _amount) = convertByPath(_path, _amount, _minReturn, fromToken, _for);

        // finished the conversion, transfer the funds to the target account
        // if the target token is an ether token, withdraw the tokens and send them as ETH
        // otherwise, transfer the tokens as is
        if (etherTokens[toToken])
            IEtherToken(toToken).withdrawTo(_for, _amount);
        else
            assert(toToken.transfer(_for, _amount));

        return _amount;
    }

    /**
        @dev executes the actual conversion by following the conversion path

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
        @param _fromToken   ERC20 token to convert from (the first element in the path)
        @param _for         account that will receive the conversion result

        @return ERC20 token to convert to (the last element in the path) & tokens issued in return
    */
    function convertByPath(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        IERC20Token _fromToken,
        address _for
    ) private returns (IERC20Token, uint256) {
        ISmartToken smartToken;
        IERC20Token toToken;
        IBancorConverter converter;

        // get the contract features address from the registry
        IContractFeatures features = IContractFeatures(registry.addressOf(ContractIds.CONTRACT_FEATURES));

        // iterate over the conversion path
        uint256 pathLength = _path.length;
        for (uint256 i = 1; i < pathLength; i += 2) {
            smartToken = ISmartToken(_path[i]);
            toToken = _path[i + 1];
            converter = IBancorConverter(smartToken.owner());
            checkWhitelist(converter, _for, features);

            // if the smart token isn't the source (from token), the converter doesn't have control over it and thus we need to approve the request
            if (smartToken != _fromToken)
                ensureAllowance(_fromToken, converter, _amount);

            // make the conversion - if it's the last one, also provide the minimum return value
            _amount = converter.convertInternal(_fromToken, toToken, _amount, i == pathLength - 2 ? _minReturn : 1);
            _fromToken = toToken;
        }
        return (toToken, _amount);
    }

    /**
        @dev returns the expected return amount for converting a specific amount by following
        a given conversion path.
        notice that there is no support for circular paths.

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)

        @return expected conversion return amount
    */
    function getReturnByPath(IERC20Token[] _path, uint256 _amount) public view returns (uint256) {
        IERC20Token fromToken;
        ISmartToken smartToken; 
        IERC20Token toToken;
        IBancorConverter converter;
        uint32 weight;
        uint256 amount;
        uint256 supply;
        ISmartToken prevSmartToken;
        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));

        amount = _amount;
        fromToken = _path[0];
        uint256 pathLength = _path.length;

        // iterate over the conversion path
        for (uint256 i = 1; i < pathLength; i += 2) {
            smartToken = ISmartToken(_path[i]);
            toToken = _path[i + 1];
            converter = IBancorConverter(smartToken.owner());

            if (toToken == smartToken) { // buy the smart token
                // check if the current smart token supply was changed in the previous iteration
                supply = smartToken == prevSmartToken ? supply : smartToken.totalSupply();

                // validate input
                require(getConnectorPurchaseEnabled(converter, fromToken));

                weight = getConnectorWeight(converter, fromToken);

                // calculate the amount minus the conversion fee
                amount = formula.calculatePurchaseReturn(supply, converter.getConnectorBalance(fromToken), weight, amount);
                amount = safeMul(amount, (MAX_CONVERSION_FEE - converter.conversionFee())) / MAX_CONVERSION_FEE;

                // update the smart token supply for the next iteration
                supply = smartToken.totalSupply() + amount;
            }
            else if (fromToken == smartToken) { // sell the smart token
                // check if the current smart token supply was changed in the previous iteration
                supply = smartToken == prevSmartToken ? supply : smartToken.totalSupply();

                weight = getConnectorWeight(converter, toToken);

                // calculate the amount minus the conversion fee
                amount = formula.calculateSaleReturn(supply, converter.getConnectorBalance(toToken), weight, amount);
                amount = safeMul(amount, (MAX_CONVERSION_FEE - converter.conversionFee())) / MAX_CONVERSION_FEE;

                // update the smart token supply for the next iteration
                supply = smartToken.totalSupply() - amount;
            }
            else { // cross connector conversion
                amount = converter.getReturn(fromToken, toToken, amount);
            }

            prevSmartToken = smartToken;
            fromToken = toToken;
        }
        return amount;
    }

    /**
        @dev checks whether the given converter supports a whitelist and if so, ensures that
        the account that should receive the conversion result is actually whitelisted

        @param _converter   converter to check for whitelist
        @param _for         account that will receive the conversion result
        @param _features    contract features contract address
    */
    function checkWhitelist(IBancorConverter _converter, address _for, IContractFeatures _features) private view {
        IWhitelist whitelist;

        // check if the converter supports the conversion whitelist feature
        if (!_features.isSupported(_converter, CONVERTER_CONVERSION_WHITELIST))
            return;

        // get the whitelist contract from the converter
        whitelist = _converter.conversionWhitelist();
        if (whitelist == address(0))
            return;

        // check if the account that should receive the conversion result is actually whitelisted
        require(whitelist.isWhitelisted(_for));
    }

    /**
        @dev claims the caller's tokens, converts them to any other token in the bancor network
        by following a predefined conversion path and transfers the result tokens to a target account
        note that allowance must be set beforehand

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero
        @param _for         account that will receive the conversion result

        @return tokens issued in return
    */
    function claimAndConvertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public returns (uint256) {
        // we need to transfer the tokens from the caller to the converter before we follow
        // the conversion path, to allow it to execute the conversion on behalf of the caller
        // note: we assume we already have allowance
        IERC20Token fromToken = _path[0];
        assert(fromToken.transferFrom(msg.sender, this, _amount));
        return convertFor(_path, _amount, _minReturn, _for);
    }

    /**
        @dev converts the token to any other token in the bancor network by following
        a predefined conversion path and transfers the result tokens back to the sender
        note that the converter should already own the source tokens

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return tokens issued in return
    */
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256) {
        return convertFor(_path, _amount, _minReturn, msg.sender);
    }

    /**
        @dev claims the caller's tokens, converts them to any other token in the bancor network
        by following a predefined conversion path and transfers the result tokens back to the sender
        note that allowance must be set beforehand

        @param _path        conversion path, see conversion path format above
        @param _amount      amount to convert from (in the initial source token)
        @param _minReturn   if the conversion results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return tokens issued in return
    */
    function claimAndConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public returns (uint256) {
        return claimAndConvertFor(_path, _amount, _minReturn, msg.sender);
    }

    /**
        @dev utility, checks whether allowance for the given spender exists and approves one if it doesn't

        @param _token   token to check the allowance in
        @param _spender approved address
        @param _value   allowance amount
    */
    function ensureAllowance(IERC20Token _token, address _spender, uint256 _value) private {
        // check if allowance for the given amount already exists
        if (_token.allowance(this, _spender) >= _value)
            return;

        // if the allowance is nonzero, must reset it to 0 first
        if (_token.allowance(this, _spender) != 0)
            assert(_token.approve(_spender, 0));

        // approve the new allowance
        assert(_token.approve(_spender, _value));
    }

    /**
        @dev returns the connector weight

        @param _converter       converter contract address
        @param _connector       connector's address to read from

        @return connector's weight
    */
    function getConnectorWeight(IBancorConverter _converter, IERC20Token _connector) 
        private
        view
        returns(uint32)
    {
        uint256 virtualBalance;
        uint32 weight;
        bool isVirtualBalanceEnabled;
        bool isPurchaseEnabled;
        bool isSet;
        (virtualBalance, weight, isVirtualBalanceEnabled, isPurchaseEnabled, isSet) = _converter.connectors(_connector);
        return weight;
    }

    /**
        @dev returns true if connector purchase enabled

        @param _converter       converter contract address
        @param _connector       connector's address to read from

        @return true if connector purchase enabled, otherwise - false
    */
    function getConnectorPurchaseEnabled(IBancorConverter _converter, IERC20Token _connector) 
        private
        view
        returns(bool)
    {
        uint256 virtualBalance;
        uint32 weight;
        bool isVirtualBalanceEnabled;
        bool isPurchaseEnabled;
        bool isSet;
        (virtualBalance, weight, isVirtualBalanceEnabled, isPurchaseEnabled, isSet) = _converter.connectors(_connector);
        return isPurchaseEnabled;
    }

    // deprecated, backward compatibility
    function convertForPrioritized(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256)
    {
        _nonce;
        convertForPrioritized2(_path, _amount, _minReturn, _for, _block, _v, _r, _s);
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

// Dependency file: @evolutionland/bancor/solidity/contracts/BancorExchange.sol

// pragma solidity ^0.4.23;

// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "@evolutionland/common/contracts/PausableDSAuth.sol";
// import "@evolutionland/common/contracts/SettingIds.sol";
// import "@evolutionland/bancor/solidity/contracts/converter/interfaces/IBancorConverter.sol";
// import "@evolutionland/bancor/solidity/contracts/token/interfaces/ISmartToken.sol";
// import "@evolutionland/bancor/solidity/contracts/IBancorNetwork.sol";


contract BancorExchange is PausableDSAuth, SettingIds {

    ISettingsRegistry registry;

    ISmartToken public smartToken;
    IBancorNetwork public bancorNetwork;
    IBancorConverter public bancorConverter;

    IERC20Token[] public quickSellPath;
    IERC20Token[] public quickBuyPath;

    // validates a conversion path - verifies that the number of elements is odd and that maximum number of 'hops' is 10
    modifier validConversionPath(IERC20Token[] _path) {
        require(_path.length > 2 && _path.length <= (1 + 2 * 10) && _path.length % 2 == 1);
        _;
    }

    constructor(address _bn, address _bc, address _registry) public {
        bancorNetwork = IBancorNetwork(_bn);
        bancorConverter = IBancorConverter(_bc);
        registry = ISettingsRegistry(_registry);
    }

    function() public payable {
        // this is necessary!
       // this is used in sell ring back to eth!
    }

    function setBancorNetwork(address _bn) public onlyOwner {
        bancorNetwork = IBancorNetwork(_bn);
    }

    function setBancorConverter(address _bc) public onlyOwner {
        bancorConverter = IBancorConverter(_bc);
    }

    function setQuickSellPath(IERC20Token[] _path)
    public
    onlyOwner
    validConversionPath(_path)
    {
        quickSellPath = _path;
    }

    function setQuickBuyPath(IERC20Token[] _path)
    public
    onlyOwner
    validConversionPath(_path)
    {
        quickBuyPath = _path;
    }

    function buyRING(uint _minReturn) public payable whenNotPaused returns (uint) {
        uint amount = bancorConverter.quickConvert.value(msg.value)(quickBuyPath, msg.value, _minReturn);
        ISmartToken smartToken = ISmartToken(registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN));
        smartToken.transfer(msg.sender, amount);
        return amount;
    }

    // this is used to buy specific amount of ring with minimum required eth
    // @param _errorSpace belongs to [0, 10000000]
    function buyRINGInMinRequiedETH(uint _minReturn, address _buyer, uint _errorSpace) public payable auth whenNotPaused returns (uint, uint) {
        ISmartToken smartToken = ISmartToken(registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN));

        (uint amountRequired) = bancorConverter.getPurchaseRequire(quickBuyPath[0], _minReturn, _errorSpace);

        require(msg.value >= amountRequired);
        uint amount = bancorConverter.quickConvert.value(amountRequired)(quickBuyPath, amountRequired, _minReturn);
        uint refundEth = msg.value - amountRequired;
        if (refundEth > 0) {
            _buyer.transfer(refundEth);
        }
        smartToken.transfer(msg.sender, amount);
        return (amount, amountRequired);
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public whenNotPaused  {
        ISmartToken smartToken = ISmartToken(registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN));

        if (address(smartToken) == msg.sender) {
            uint minReturn = bytesToUint256(_data);
            smartToken.transfer(address(bancorNetwork), _value);
            // cant replace address(this) with _from
            // because of whitelist mechanism in bancor protocol
            uint amount = bancorNetwork.convertForPrioritized2(quickSellPath, _value, minReturn, address(this), 0, 0, 0x0, 0x0);
            _from.transfer(amount);
        }
    }

    // @dev before invoke sellRING, make sure approve to exchange before in RING contract
    // @param _sellAmount amount of ring you want to sell
    // @param _minReturn minimum amount of ETH you expect
    function sellRING(uint _sellAmount, uint _minReturn) public whenNotPaused {
        ISmartToken smartToken = ISmartToken(registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN));

        smartToken.transferFrom(msg.sender, address(bancorNetwork), _sellAmount);
        // cant replace address(this) with msg.sender
        // because of whitelist mechanism in bancor protocol
        uint amount = bancorNetwork.convertForPrioritized2(quickSellPath, _sellAmount, _minReturn, address(this), 0, 0, 0x0, 0x0);
        msg.sender.transfer(amount);
    }


    function bytesToUint256(bytes b) public pure returns (uint256) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return uint256(out);
    }


    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        IERC20Token token = IERC20Token(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }

    function setRegistry(address _registry) public onlyOwner {
        registry = ISettingsRegistry(_registry);
    }


}

// Dependency file: @evolutionland/land/contracts/LandBaseAuthority.sol

// pragma solidity ^0.4.24;

contract LandBaseAuthority {

    constructor(address[] _whitelists) public {
        for (uint i = 0; i < _whitelists.length; i ++) {
            whiteList[_whitelists[i]] = true;
        }
    }

    mapping (address => bool) public whiteList;

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return ( whiteList[_src] && _sig == bytes4(keccak256("setResourceRateAttr(uint256,uint256)")) ) ||
               ( whiteList[_src] && _sig == bytes4(keccak256("setResourceRate(uint256,address,uint16)")) ) ||
               ( whiteList[_src] && _sig == bytes4(keccak256("setHasBox(uint256,bool)"))) ||
                ( whiteList[_src] && _sig == bytes4(keccak256("assignNewLand(int256,int256,address,uint256,uint256)")));
    }
}

// Dependency file: @evolutionland/upgraeability-using-unstructured-storage/contracts/Proxy.sol

// pragma solidity ^0.4.21;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable public {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}


// Dependency file: @evolutionland/upgraeability-using-unstructured-storage/contracts/UpgradeabilityProxy.sol

// pragma solidity ^0.4.21;

// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/upgraeability-using-unstructured-storage/contracts/Proxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param implementation representing the address of the upgraded implementation
   */
  event Upgraded(address indexed implementation);

  // Storage position of the address of the current implementation
  bytes32 private constant implementationPosition = keccak256("org.zeppelinos.proxy.implementation");

  /**
   * @dev Constructor function
   */
  function UpgradeabilityProxy() public {}

  /**
   * @dev Tells the address of the current implementation
   * @return address of the current implementation
   */
  function implementation() public view returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param newImplementation address representing the new implementation to be set
   */
  function setImplementation(address newImplementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, newImplementation)
    }
  }

  /**
   * @dev Upgrades the implementation address
   * @param newImplementation representing the address of the new implementation to be set
   */
  function _upgradeTo(address newImplementation) internal {
    address currentImplementation = implementation();
    require(currentImplementation != newImplementation);
    setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }
}


// Dependency file: @evolutionland/upgraeability-using-unstructured-storage/contracts/OwnedUpgradeabilityProxy.sol

// pragma solidity ^0.4.21;

// import '/Users/echo/workspace/contract/evolutionlandorg/evo-deploy/lib/market-contracts/node_modules/@evolutionland/upgraeability-using-unstructured-storage/contracts/UpgradeabilityProxy.sol';

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  // Storage position of the owner of the contract
  bytes32 private constant proxyOwnerPosition = keccak256("org.zeppelinos.proxy.owner");

  /**
  * @dev the constructor sets the original owner of the contract to the sender account.
  */
  function OwnedUpgradeabilityProxy() public {
    setUpgradeabilityOwner(msg.sender);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
   * @dev Tells the address of the owner
   * @return the address of the owner
   */
  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }

  /**
   * @dev Sets the address of the owner
   */
  function setUpgradeabilityOwner(address newProxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, newProxyOwner)
    }
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradeabilityOwner(newOwner);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy.
   * @param implementation representing the address of the new implementation to be set.
   */
  function upgradeTo(address implementation) public onlyProxyOwner {
    _upgradeTo(implementation);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
   * to initialize whatever is needed through a low level call.
   * @param implementation representing the address of the new implementation to be set.
   * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
   * signature of the implementation to be called with the needed payload
   */
  function upgradeToAndCall(address implementation, bytes data) payable public onlyProxyOwner {
    upgradeTo(implementation);
    require(this.call.value(msg.value)(data));
  }
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


// Dependency file: @evolutionland/common/contracts/UserPoints.sol

// pragma solidity ^0.4.24;

// import "@evolutionland/common/contracts/DSAuth.sol";
// import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "@evolutionland/common/contracts/interfaces/IUserPoints.sol";

contract UserPoints is DSAuth, IUserPoints {
    using SafeMath for *;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    bool private singletonLock = false;

    // points
    mapping (address => uint256) public points;

    uint256 public allUserPoints;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract() public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function pointsSupply() public view returns (uint256) {
        return allUserPoints;
    }

    function pointsBalanceOf(address _user) public view returns (uint256) {
        return points[_user];
    }

    function addPoints(address _user, uint256 _pointAmount) public auth {
        points[_user] = points[_user].add(_pointAmount);
        allUserPoints = allUserPoints.add(_pointAmount);

        emit AddedPoints(_user, _pointAmount);
    }

    function subPoints(address _user, uint256 _pointAmount) public auth {
        points[_user] = points[_user].sub(_pointAmount);
        allUserPoints = allUserPoints.sub(_pointAmount);
        emit SubedPoints(_user, _pointAmount);
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

// Dependency file: @evolutionland/common/contracts/UserPointsAuthority.sol

// pragma solidity ^0.4.24;

contract UserPointsAuthority {
    mapping (address => bool) public whiteList;

    constructor(address[] _whitelists) public {
        for (uint i = 0; i < _whitelists.length; i ++) {
            whiteList[_whitelists[i]] = true;
        }
    }

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return ( whiteList[_src] && _sig == bytes4(keccak256("addPoints(address,uint256)"))) ||
        ( whiteList[_src] && _sig == bytes4(keccak256("subPoints(address,uint256)")));
    }
}


// Dependency file: @evolutionland/land/contracts/interfaces/IMysteriousTreasure.sol

// pragma solidity ^0.4.24;

contract IMysteriousTreasure {

    function unbox(uint256 _tokenId) public returns (uint, uint, uint, uint, uint);

}

// Dependency file: @evolutionland/land/contracts/MysteriousTreasure.sol

// pragma solidity ^0.4.23;

// import "openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "@evolutionland/common/contracts/DSAuth.sol";
// import "@evolutionland/common/contracts/SettingIds.sol";
// import "@evolutionland/land/contracts/interfaces/ILandBase.sol";
// import "@evolutionland/land/contracts/interfaces/IMysteriousTreasure.sol";

contract MysteriousTreasure is DSAuth, SettingIds, IMysteriousTreasure {
    using SafeMath for *;
    
    bool private singletonLock = false;

    ISettingsRegistry public registry;

    // the key of resourcePool are 0,1,2,3,4
    // respectively refer to gold,wood,water,fire,soil
    mapping (uint256 => uint256) public resourcePool;

    // number of box left
    uint public totalBoxNotOpened;

    // event unbox
    event Unbox(uint indexed tokenId, uint goldRate, uint woodRate, uint waterRate, uint fireRate, uint soilRate);

    /*
  *  Modifiers
  */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    // this need to be created in ClockAuction cotnract
    constructor() public {

      // initializeContract
    }

    function initializeContract(ISettingsRegistry _registry, uint256[5] _resources) public singletonLockCall {
        owner = msg.sender;

        registry = _registry;

        totalBoxNotOpened = 176;
        for(uint i = 0; i < 5; i++) {
            _setResourcePool(i, _resources[i]);
        }
    }

    //TODO: consider authority again
    // this is invoked in auction.claimLandAsset
    function unbox(uint256 _tokenId)
    public
    auth
    returns (uint, uint, uint, uint, uint) {
        ILandBase landBase = ILandBase(registry.addressOf(SettingIds.CONTRACT_LAND_BASE));
        if(! landBase.isHasBox(_tokenId) ) {
            return (0,0,0,0,0);
        }

        // after unboxing, set hasBox(tokenId) to false to restrict unboxing
        // set hasBox to false before unboxing operations for safety reason
        landBase.setHasBox(_tokenId, false);

        uint16[5] memory resourcesReward;
        (resourcesReward[0], resourcesReward[1],
        resourcesReward[2], resourcesReward[3], resourcesReward[4]) = _computeAndExtractRewardFromPool();

        address resouceToken = registry.addressOf(SettingIds.CONTRACT_GOLD_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[0]);

        resouceToken = registry.addressOf(SettingIds.CONTRACT_WOOD_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[1]);

        resouceToken = registry.addressOf(SettingIds.CONTRACT_WATER_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[2]);

        resouceToken = registry.addressOf(SettingIds.CONTRACT_FIRE_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[3]);

        resouceToken = registry.addressOf(SettingIds.CONTRACT_SOIL_ERC20_TOKEN);
        landBase.setResourceRate(_tokenId, resouceToken, landBase.getResourceRate(_tokenId, resouceToken) + resourcesReward[4]);

        // only record increment of resources
        emit Unbox(_tokenId, resourcesReward[0], resourcesReward[1], resourcesReward[2], resourcesReward[3], resourcesReward[4]);

        return (resourcesReward[0], resourcesReward[1], resourcesReward[2], resourcesReward[3], resourcesReward[4]);
    }

    // rewards ranges from [0, 2 * average_of_resourcePool_left]
    // if early players get high resourceReward, then the later ones will get lower.
    // in other words, if early players get low resourceReward, the later ones get higher.
    // think about snatching wechat's virtual red envelopes in groups.
    function _computeAndExtractRewardFromPool() internal returns(uint16,uint16,uint16,uint16,uint16) {
        if ( totalBoxNotOpened == 0 ) {
            return (0,0,0,0,0);
        }

        uint16[5] memory resourceRewards;

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
                // 2 ** 16 - 1
                uint doubleAverage = (2 * resourcePool[i] / totalBoxNotOpened);
                if (doubleAverage > 65535) {
                    doubleAverage = 65535;
                }
                
                uint resourceReward = seed % doubleAverage;

                resourceRewards[i] = uint16(resourceReward);
                
                // update resourcePool
                _setResourcePool(i, resourcePool[i] - resourceRewards[i]);
            }

            if(totalBoxNotOpened == 1) {
                resourceRewards[i] = uint16(resourcePool[i]);
                _setResourcePool(i, resourcePool[i] - uint256(resourceRewards[i]));
            }
        }

        totalBoxNotOpened--;

        return (resourceRewards[0],resourceRewards[1], resourceRewards[2], resourceRewards[3], resourceRewards[4]);

    }


    function _setResourcePool(uint _keyNumber, uint _resources) internal {
        require(_keyNumber >= 0 && _keyNumber < 5);
        resourcePool[_keyNumber] = _resources;
    }

    function setResourcePool(uint _keyNumber, uint _resources) public auth {
        _setResourcePool(_keyNumber, _resources);
    }

    function setTotalBoxNotOpened(uint _totalBox) public auth {
        totalBoxNotOpened = _totalBox;
    }

}


// Dependency file: @evolutionland/common/contracts/MintAndBurnAuthority.sol

// pragma solidity ^0.4.24;

contract MintAndBurnAuthority {

    mapping (address => bool) public whiteList;

    constructor(address[] _whitelists) public {
        for (uint i = 0; i < _whitelists.length; i ++) {
            whiteList[_whitelists[i]] = true;
        }
    }

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return ( whiteList[_src] && _sig == bytes4(keccak256("mint(address,uint256)")) ) ||
        ( whiteList[_src] && _sig == bytes4(keccak256("burn(address,uint256)")) );
    }
}


// Dependency file: @evolutionland/bancor/solidity/contracts/BancorExchangeAuthority.sol

// pragma solidity ^0.4.24;

// import "@evolutionland/common/contracts/interfaces/IAuthority.sol";

contract BancorExchangeAuthority is IAuthority {

    mapping (address => bool) public whiteList;

    constructor(address[] _whitelists) public {
        for (uint i = 0; i < _whitelists.length; i ++) {
            whiteList[_whitelists[i]] = true;
        }
    }

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return ( whiteList[_src] && _sig == bytes4(keccak256("buyRINGInMinRequiedETH(uint256,address,uint256)"))) ;
    }
}

// Root file: contracts/DeployAndTest.sol

pragma solidity ^0.4.23;

//// import "@evolutionland/common/contracts/SettingsRegistry.sol";
//// import "@evolutionland/common/contracts/StandardERC223.sol";
//// import "@evolutionland/common/contracts/ObjectOwnership.sol";
//// import "@evolutionland/land/contracts/LandBase.sol";
//// import "@evolutionland/bancor/solidity/contracts/converter/BancorConverter.sol";
//// import "@evolutionland/bancor/solidity/contracts/converter/BancorFormula.sol";
//// import "@evolutionland/bancor/solidity/contracts/converter/BancorGasPriceLimit.sol";
//// import "@evolutionland/bancor/solidity/contracts/token/EtherToken.sol";
//// import "@evolutionland/bancor/solidity/contracts/utility/ContractFeatures.sol";
//// import "@evolutionland/bancor/solidity/contracts/utility/Whitelist.sol";
//// import "@evolutionland/bancor/solidity/contracts/BancorNetwork.sol";
//// import "@evolutionland/bancor/solidity/contracts/BancorExchange.sol";
//// import "@evolutionland/bancor/solidity/contracts/ContractIds.sol";
//// import "@evolutionland/bancor/solidity/contracts/FeatureIds.sol";
//// import "@evolutionland/land/contracts/LandBaseAuthority.sol";
//// import "@evolutionland/upgraeability-using-unstructured-storage/contracts/OwnedUpgradeabilityProxy.sol";
//// import "@evolutionland/common/contracts/UserPoints.sol";
//// import "@evolutionland/common/contracts/UserPointsAuthority.sol";
//// import "@evolutionland/land/contracts/MysteriousTreasure.sol";
//// import "@evolutionland/common/contracts/MintAndBurnAuthority.sol";
//// import "@evolutionland/bancor/solidity/contracts/BancorExchangeAuthority.sol";


contract DeployAndTest {

}