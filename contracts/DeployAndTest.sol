pragma solidity ^0.4.23;

import "@evolutionland/land/contracts/land/Atlantis.sol";
import "evolutionlandcommon/contracts/SettingsRegistry.sol";
import "evolutionlandcommon/contracts/StandardERC223.sol";
import "@evolutionland/land/contracts/land/LandGenesisData.sol";
import "@evolutionland/land/contracts/land/Atlantis.sol";
import "@evolutionland/bancor/solidity/contracts/converter/BancorConverter.sol";
import "@evolutionland/bancor/solidity/contracts/converter/BancorFormula.sol";
import "@evolutionland/bancor/solidity/contracts/converter/BancorGasPriceLimit.sol";
import "@evolutionland/bancor/solidity/contracts/token/EtherToken.sol";
import "@evolutionland/bancor/solidity/contracts/utility/ContractFeatures.sol";
import "@evolutionland/bancor/solidity/contracts/utility/ContractRegistry.sol";
import "@evolutionland/bancor/solidity/contracts/utility/Whitelist.sol";
import "@evolutionland/bancor/solidity/contracts/BancorNetwork.sol";
import "@evolutionland/bancor/solidity/contracts/BancorExchange.sol";
import "@evolutionland/bancor/solidity/contracts/ContractIds.sol";
import "@evolutionland/bancor/solidity/contracts/FeatureIds.sol";
import "@evolutionland/bancor/solidity/contracts/token/SmartToken.sol";

contract DeployAndTest {
    function getTxPrice() public returns (uint) {
        uint price = tx.gasprice;
        return price;
    }

}