pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "@evolutionland/common/contracts/interfaces/ERC223ReceivingContract.sol";
import "@evolutionland/common/contracts/SettingIds.sol";
import "@evolutionland/common/contracts/interfaces/ERC223.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

// Use proxy mode
contract RevenuePool is Ownable, ERC223ReceivingContract, SettingIds {

    // 10%
    address public tradingRewardPool;
    // 30%
    address public contributionIncentivePool;
    // 30%
    address public dividendsPool;
    // 30%
    address public devPool;

    ISettingsRegistry public registry;
    bool private singletonLock = false;
    address genesisHolder;

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

        if(msg.sender == genesisHolder) {
            return;
        }
    }

    function setPoolAddresses(address _tradingRewardPool, address _contributionIncentivePool, address _dividendsPool, address _devPool, address _genesisHolder)
    public
    onlyOwner {
        tradingRewardPool = _tradingRewardPool;
        contributionIncentivePool = _contributionIncentivePool;
        dividendsPool = _dividendsPool;
        devPool = _devPool;
        genesisHolder = _genesisHolder;
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








}
