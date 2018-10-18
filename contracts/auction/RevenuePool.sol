pragma solidity ^0.4.24;

import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "@evolutionland/common/contracts/interfaces/ERC223ReceivingContract.sol";
import "@evolutionland/common/contracts/SettingIds.sol";
import "@evolutionland/common/contracts/interfaces/ERC223.sol";
import "@evolutionland/common/contracts/RBACWithAuth.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

// Use proxy mode
// recommond to use RBACWithAuth and add functions to modify tickets
contract RevenuePool is RBACWithAuth, ERC223ReceivingContract, SettingIds {

    bool private singletonLock = false;

    // 10%
    address public tradingRewardPool;
    // 30%
    address public contributionIncentivePool;
    // 30%
    address public dividendsPool;
    // 30%
    address public devPool;

    ISettingsRegistry public registry;

    // tickets
    mapping (address => uint256) public tickets;

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
        addRole(msg.sender, ROLE_ADMIN);
        addRole(msg.sender, ROLE_AUTH_CONTROLLER);

        registry = ISettingsRegistry(_registry);
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public {

        address ring = registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN);

        if(msg.sender == ring) {
            address buyer = bytesToAddress(_data);
            // should same with trading reward percentage in settleToken;
            tickets[buyer] += _value / 10;
        }
    }

    function setPoolAddresses(address _tradingRewardPool, address _contributionIncentivePool, address _dividendsPool, address _devPool)
    public
    isAuth {
        tradingRewardPool = _tradingRewardPool;
        contributionIncentivePool = _contributionIncentivePool;
        dividendsPool = _dividendsPool;
        devPool = _devPool;
    }

    function updateTickets(address _user, uint _newTicket) public isAuth {
        tickets[_user] = _newTicket;
    }

    function settleToken(address _tokenAddress) public {
        require(tradingRewardPool != 0x0 && contributionIncentivePool != 0x0 && dividendsPool != 0x0 && devPool != 0x0);

        uint balance = ERC20(_tokenAddress).balanceOf(address(this));

        require(ERC223(_tokenAddress).transfer(tradingRewardPool, balance / 10, "0x0"));
        require(ERC223(_tokenAddress).transfer(contributionIncentivePool, balance * 3 / 10, "0x0"));
        require(ERC223(_tokenAddress).transfer(dividendsPool, balance * 3 / 10, "0x0"));
        require(ERC223(_tokenAddress).transfer(devPool, balance * 3 / 10, "0x0"));
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyAdmin {
        if (_token == 0x0) {
            msg.sender.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);

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
