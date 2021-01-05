// Root file: contracts/auction/interfaces/IGovernorPool.sol

pragma solidity ^0.4.24;

contract IGovernorPool {
    function checkRewardAvailable(address _token) external view returns(bool);
    function rewardAmount(uint256 _amount) external; 
}
