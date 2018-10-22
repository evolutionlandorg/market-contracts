pragma solidity ^0.4.24;

import "@evolutionland/common/contracts/interfaces/IAuthority.sol";

contract TradingRewardPoolAuthority is IAuthority {
    mapping (address => bool) public whiteList;

    constructor(address[] _whitelists) public {
        for (uint i = 0; i < _whitelists.length; i ++) {
            whiteList[_whitelists[i]] = true;
        }
    }

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return ( whiteList[_src] && _sig == bytes4(keccak256("addTickets(address,uint256)"))) ||
        ( whiteList[_src] && _sig == bytes4(keccak256("clearTicket(address)")));
    }
}
