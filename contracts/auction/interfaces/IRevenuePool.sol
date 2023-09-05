pragma solidity >=0.4.24;

interface IRevenuePool {
    function reward(address _token, uint256 _value, address _buyer) external;
    function settleToken(address _tokenAddress) external;
}
