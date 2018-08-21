pragma solidity ^0.4.23;

interface ILandData {

    function addLandPixel(uint256 _tokenId, uint256 _landAttribute) public;
    function batchAdd(uint256[] _tokenIds, uint256[] _landAttributes) public;
    function modifyAttibutes(uint _tokenId, uint _right, uint _left, uint _newValue) public;
    function getXY(uint _tokenId) public view returns (int16 x, int16 y);

    function getGoldRate(uint _tokenId) public view returns (uint);
    function getWoodRate(uint _tokenId) public view returns (uint);
    function getWaterRate(uint _tokenId) public view returns (uint);
    function getFireRate(uint _tokenId) public view returns (uint);
    function getSoilRate(uint _tokenId) public view returns (uint);

    function isReserved(uint256 _tokenId) public view returns (bool);
    function isSpecial(uint256 _tokenId) public view returns (bool);
    function hasBox(uint256 _tokenId) public view returns (bool);

    function getInfoFromAttibutes(uint256 _attibutes, uint _rightAt, uint _leftAt) public returns (uint);
    function encodeTokenId(int _x, int _y) pure public returns (uint);


}