pragma solidity ^0.4.24;

contract ITradingRewardPool {
    event RewardClaimedWithTicket(address indexed user, uint256 ticketAmount, uint256 rewardAmount);

    event UpdatedTicketAmount(address indexed user, uint256 newTicketAmount);

    function claimTicketReward() public;

    function addTickets(address _user, uint256 _addTicketAmount) public;

    function clearTicket(address _user) public;
}
