pragma solidity ^0.4.24;

import "@evolutionland/common/contracts/PausableDSAuth.sol";
import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./RevenuePool.sol";
import "./AuctionSettingIds.sol";

contract PointsRewardPoolV2 is PausableDSAuth, AuctionSettingIds {
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
        return ERC20(_token).balanceOf(address(this)) + ERC20(_token).balanceOf(registry.addressOf(CONTRACT_REVENUE_POOL)) * 4 / 10;
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
