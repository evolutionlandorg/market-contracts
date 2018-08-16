pragma solidity ^0.4.23;

interface ILandData {

    function addLandPixel(
        int64 _x,
        int64 _y,
        int64 _z,
        uint64 _goldRate,
        uint64 _woodRate,
        uint64 _waterRate,
        uint64 _fireRate,
        uint64 _soilRate,
        uint256 _flag)
    public;


    function getPixelInfoWithPosition(int64 _x, int64 _y)
    public
    view
    returns (uint64,uint64,uint64,uint64,uint64,uint256);


    function getPixelInfoWithTokenId(uint256 _tokenId)
    public
    view
    returns (int64,int64,int64,uint64,uint64,uint64,uint64,uint64,uint256);

    function getInfoFromFlag(uint256 _flag, uint _rightAt, uint _leftAt) public;

    function isReserved(uint256 _tokenId) public returns (bool);

    function isSpecial(uint256 _tokenId) public returns (bool);


}