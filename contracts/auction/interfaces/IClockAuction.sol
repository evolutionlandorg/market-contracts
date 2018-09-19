pragma solidity ^0.4.23;

contract IClockAuction {
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        address _token)
    public;

    function cancelAuction(uint256 _tokenId)
    public;
}
