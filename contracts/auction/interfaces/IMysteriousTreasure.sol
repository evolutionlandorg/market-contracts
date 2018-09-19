pragma solidity ^0.4.24;

contract IMysteriousTreasure {

    function unbox(uint256 _tokenId) public returns (uint, uint, uint, uint, uint);
    function transferOwnership(address _newOwner) public;

}