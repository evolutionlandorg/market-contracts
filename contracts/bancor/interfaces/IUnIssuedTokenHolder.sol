pragma solidity ^0.4.24;

contract IUnIssuedTokenHolder {
    function originToken() public view returns (address);

    function smartToken() public view returns (address);

    function issue(address _to, uint256 _amount) public;

    function destroy(address _from, uint256 _amount) public;
}