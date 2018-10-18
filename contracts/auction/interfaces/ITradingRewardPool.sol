pragma solidity ^0.4.24;

contract ITradingRewardPool {
    event RewardClaimedWithTicket(address indexed user, uint256 ticketAmount, uint256 rewardAmount);

    function claimTicketReward() public;
}
