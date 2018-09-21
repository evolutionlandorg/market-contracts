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



contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}
