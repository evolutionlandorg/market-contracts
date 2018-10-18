pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "@evolutionland/common/contracts/interfaces/ERC223ReceivingContract.sol";
import "@evolutionland/common/contracts/SettingIds.sol";
import "@evolutionland/common/contracts/interfaces/ERC223.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

// Use proxy mode
// recommond to use RBACWithAuth and add functions to modify tickets
contract RevenuePool is Ownable, ERC223ReceivingContract, SettingIds {

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
        owner = msg.sender;
        registry = ISettingsRegistry(_registry);
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public {

        address ring = registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN);

        if(msg.sender == ring) {
            address buyer = bytesToAddress(_data);
            tickets[buyer] += _value;
        }
    }

    function setPoolAddresses(address _tradingRewardPool, address _contributionIncentivePool, address _dividendsPool, address _devPool)
    public
    onlyOwner {
        tradingRewardPool = _tradingRewardPool;
        contributionIncentivePool = _contributionIncentivePool;
        dividendsPool = _dividendsPool;
        devPool = _devPool;
    }

    function batchTransfer(address _tokenAddress) public {
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

    function bytesToAddress(bytes b) public pure returns (address) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return address(out);
    }








}
