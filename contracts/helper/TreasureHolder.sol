pragma solidity ^0.4.23;

import "../auction/interfaces/IMysteriousTreasure.sol";

contract TreasureHolder is Ownable {

    function transferTreasureOwnership(address _newOwner) public onlyOwner {
        IMysteriousTreasure mysteriousTreasure = IMysteriousTreasure(registry.addressOf(AuctionSettingIds.CONTRACT_MYSTERIOUS_TREASURE));
        mysteriousTreasure.transferOwnership(_newOwner);
    }

}
