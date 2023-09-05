pragma solidity ^0.4.24;

import "@evolutionland/common/contracts/PausableDSAuth.sol";
import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "@evolutionland/common/contracts/interfaces/IUserPoints.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interfaces/IRevenuePool.sol";
import "./AuctionSettingIds.sol";
import "./interfaces/IERC20.sol";

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

    function playWithSmallTicket() public isHuman whenNotPaused {
        _play(10 ether, 8);
    }

    function playWithLargeTicket() public isHuman whenNotPaused {
        _play(100 ether, 10);
    }

    function totalRewardInPool(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this)) + IERC20(_token).balanceOf(registry.addressOf(CONTRACT_REVENUE_POOL)) / 10;
    }

    function _play(uint _pointAmount, uint _houseEdgeDenominator) internal {
        // settlement by the way.
        address revenuePool = registry.addressOf(CONTRACT_REVENUE_POOL);
        IUserPoints userPoints = IUserPoints(registry.addressOf(CONTRACT_USER_POINTS));

        IRevenuePool(revenuePool)
            .settleToken(registry.addressOf(CONTRACT_RING_ERC20_TOKEN));

        userPoints.subPoints(msg.sender, _pointAmount);

        uint256 seed = uint256(keccak256(abi.encodePacked(
                gasleft(),
                block.timestamp,
                block.difficulty,
                block.coinbase,
                block.gaslimit,
                tx.origin,
                block.number
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

        uint256 rewardTokens = rewardPoints.mul(IERC20(ring).balanceOf(address(this))).div(pointsSupply);

        IERC20(ring).transfer(msg.sender, rewardTokens);

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
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

}
