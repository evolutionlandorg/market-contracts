pragma solidity ^0.4.23;

interface ILandData {

    function modifyAttributes(uint _tokenId, uint _right, uint _left, uint _newValue) public;

    function isReserved(uint256 _tokenId) public view returns (bool);
    function isSpecial(uint256 _tokenId) public view returns (bool);
    function hasBox(uint256 _tokenId) public view returns (bool);

    function getDetailsFromLandInfo(uint _tokenId)
    public
    view
    returns (
        uint goldRate,
        uint woodRate,
        uint waterRate,
        uint fireRate,
        uint soilRate,
        uint flag);

    function encodeTokenId(int _x, int _y) pure public returns (uint);


}