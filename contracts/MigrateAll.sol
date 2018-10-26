pragma solidity ^0.4.23;

// common
import "@evolutionland/common/contracts/InterstellarEncoder.sol";
import "@evolutionland/common/contracts/MintAndBurnAuthority.sol";
import "@evolutionland/common/contracts/ObjectOwnership.sol";
import "@evolutionland/common/contracts/ObjectOwnershipAuthority.sol";
import "@evolutionland/common/contracts/SettingsRegistry.sol";
import "@evolutionland/common/contracts/StandardERC223.sol";
import "@evolutionland/common/contracts/TokenLocation.sol";
import "@evolutionland/common/contracts/TokenLocationAuthority.sol";
import "@evolutionland/common/contracts/UserPoints.sol";
import "@evolutionland/common/contracts/UserPointsAuthority.sol";

// land
import "@evolutionland/land/contracts/LandBase.sol";
import "@evolutionland/land/contracts/LandBaseAuthority.sol";
import "@evolutionland/land/contracts/MysteriousTreasure.sol";

// bancor
import "@evolutionland/bancor/solidity/contracts/BancorExchange.sol";
import "@evolutionland/bancor/solidity/contracts/BancorExchangeAuthority.sol";
import "@evolutionland/bancor/solidity/contracts/BancorNetwork.sol";
import "@evolutionland/bancor/solidity/contracts/ContractIds.sol";
import "@evolutionland/bancor/solidity/contracts/FeatureIds.sol";
import "@evolutionland/bancor/solidity/contracts/converter/BancorConverter.sol";
import "@evolutionland/bancor/solidity/contracts/converter/BancorFormula.sol";
import "@evolutionland/bancor/solidity/contracts/converter/BancorGasPriceLimit.sol";
import "@evolutionland/bancor/solidity/contracts/token/EtherToken.sol";
import "@evolutionland/bancor/solidity/contracts/token/SmartToken.sol";
import "@evolutionland/bancor/solidity/contracts/utility/ContractFeatures.sol";
import "@evolutionland/bancor/solidity/contracts/utility/Whitelist.sol";

// bank
import "@evolutionland/bank/contracts/BankSettingIds.sol";
import "@evolutionland/bank/contracts/GringottsBank.sol";
import "@evolutionland/bank/contracts/KTONAuthority.sol";


contract MigrateAll {

}
