pragma solidity ^0.4.23;

import "./ILandData.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract RewardBox is Ownable {
    using SafeMath for *;

    ILandData public landData;

    // the key of resourcePool are 0,1,2,3,4
    // respectively refer to gold,wood,water,fire,soil
    mapping (uint256 => uint256) public resourcePool;

    // number of box left
    uint public totalBoxNotOpened;

    // this need to be created in ClockAuction cotnract
    constructor(address _landData, uint256[5] _resources) public {
        landData = ILandData(_landData);
        totalBoxNotOpened = 176;
        for(uint i = 0; i < 5; i++) {
            _setResourcePool(i, _resources[i]);
        }
    }

    //TODO: consider authority again
    function unbox(uint256 _tokenId)
    public
    returns (uint, uint, uint, uint, uint){
        // this is invoked in auction.claimLandAsset
        require(msg.sender == owner);

        //resourcesExist[0, 4] is gold,wood,water,fire,soil resources rate's limit
        // resourcesExist[5] is flag, and not used
        uint[6] memory resourcesExist;
        (resourcesExist[0],resourcesExist[1],resourcesExist[2],resourcesExist[3],
        resourcesExist[4],resourcesExist[5]) = landData.getDetailsFromLandInfo(_tokenId);

        uint[5] memory resourcesReward;
        (resourcesReward[0], resourcesReward[1],
        resourcesReward[2], resourcesReward[3], resourcesReward[4]) = _computeReward();

        for(uint i = 0; i < 5; i++) {
            landData.modifyAttributes(_tokenId, 16*i, 15+16*i, resourcesReward[i] + resourcesExist[i]);
        }

        return (resourcesReward[0], resourcesReward[1], resourcesReward[2],
        resourcesReward[3], resourcesReward[4]);
    }

    // rewards ranges from [0, 2 * average_of_resourcePool_left]
    // if early players get high resourceReward, then the later ones will get lower.
    // in other words, if early players get low resourceReward, the later ones get higher.
    // think about snatching wechat's virtual red envelopes in groups.
    function _computeReward() internal returns(uint,uint,uint,uint,uint) {
        require(totalBoxNotOpened > 0);

        uint[5] memory resourceRewards;
        // from fomo3d
        // msg.sender is always address(auction),
        // so change msg.sender to tx.origin
        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(tx.origin)))) / (now)).add
                (block.number)
            )));


            for(uint i = 0; i < 5; i++) {
                if (totalBoxNotOpened > 1) {
                    // recources in resourcePool is set by owner
                    // nad totalBoxNotOpened is set by rules
                    // there is no need to consider overflow
                // goldReward, woodReward, waterReward, fireReward, soilReward
                resourceRewards[i] = seed % (2 * resourcePool[i] / totalBoxNotOpened);
                // update resourcePool
                _setResourcePool(i, resourcePool[i] - resourceRewards[i]);
                }

                if(totalBoxNotOpened == 1) {
                    resourceRewards[i] = resourcePool[i];
                    _setResourcePool(i, resourcePool[i] - resourceRewards[i]);
                }
        }

        totalBoxNotOpened--;

        return (resourceRewards[0],resourceRewards[1], resourceRewards[2], resourceRewards[3], resourceRewards[4]);

    }


    function _setResourcePool(uint _keyNumber, uint _resources) internal {
        require(_keyNumber >= 0 && _keyNumber < 5);
        resourcePool[_keyNumber] = _resources;
    }

}
