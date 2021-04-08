// Root file: contracts/auction/interfaces/IInterstellarEncoder.sol

pragma solidity ^0.4.24;

contract IInterstellarEncoder {
    enum ObjectClass { 
        NaN,
        LAND,
        APOSTLE,
        OBJECT_CLASS_COUNT
    }
    function getObjectClass(uint256 _tokenId) external view returns (uint8);
}
