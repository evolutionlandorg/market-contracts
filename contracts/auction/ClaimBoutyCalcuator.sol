pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract ClaimBountyCalculator is Ownable {
    mapping (address => uint256) tokenBountyAmounts;

    function tokenAmountForBounty(address _token) public view returns (uint256)
    {
        return tokenBountyAmounts[_token];
    }

    function setTokenAmountForBounty(address _token, uint256 _amount) public onlyOwner {
        tokenBountyAmounts[_token] = _amount;
    }
}