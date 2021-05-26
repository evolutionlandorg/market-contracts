pragma solidity ^0.4.24;

import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
// import "@evolutionland/common/contracts/interfaces/IUserPoints.sol";
import "@evolutionland/common/contracts/DSAuth.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./AuctionSettingIds.sol";

/**
 * @title RevenuePool
 * difference between LandResourceV1:
     change DividendPool into governorPool for reward
 */

// Use proxy mode
contract RevenuePoolV3 is DSAuth, AuctionSettingIds {

    bool private singletonLock = false;

//    // 40%
//    address public pointsRewardPool;
//    // 30%
//    address public contributionIncentivePool;
//    // 0%
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

    function settleToken(address _tokenAddress) public {
        uint balance = ERC20(_tokenAddress).balanceOf(address(this));

        // to save gas when playing
        if (balance > 10) {
            address pointsRewardPool = registry.addressOf(AuctionSettingIds.CONTRACT_POINTS_REWARD_POOL);
            address contributionIncentivePool = registry.addressOf(AuctionSettingIds.CONTRACT_CONTRIBUTION_INCENTIVE_POOL);
            address governorPool = registry.addressOf(CONTRACT_DIVIDENDS_POOL);
            address devPool = registry.addressOf(AuctionSettingIds.CONTRACT_DEV_POOL);

            require(pointsRewardPool != 0x0 && contributionIncentivePool != 0x0 && governorPool != 0x0 && devPool != 0x0, "invalid addr");

            require(ERC20(_tokenAddress).transfer(pointsRewardPool, balance * 4 / 10));
            require(ERC20(_tokenAddress).transfer(contributionIncentivePool, balance * 3 / 10));
            require(ERC20(_tokenAddress).transfer(devPool, balance * 3 / 10));
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
}
