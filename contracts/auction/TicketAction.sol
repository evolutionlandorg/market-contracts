pragma solidity ^0.4.24;

import "@evolutionland/common/contracts/RBACWithAuth.sol";
import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "@evolutionland/common/contracts/SettingIds.sol";
import "./RevenuePool.sol";
import "./interfaces/ITicketAction.sol";

contract TicketAuction is RBACWithAuth, ITicketAction, SettingIds {
    address public revenuePool;

    ISettingsRegistry public registry;

    constructor(address _revenuePool) public {
        revenuePool = revenuePool;
    }

    function lotteryWithTicket() public {
        require(msg.sender == tx.origin, "Robot is not allowed.");

        RevenuePool(revenuePool).settleToken(registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN));

        // TODO:
    }
}