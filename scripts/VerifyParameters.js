const StandardERC223 = artifacts.require('StandardERC223');
const InterstellarEncoder = artifacts.require('InterstellarEncoder');
const SettingsRegistry = artifacts.require('SettingsRegistry');
const SettingIds = artifacts.require('SettingIds');
const LandBase = artifacts.require('LandBase');
const ObjectOwnership = artifacts.require('ObjectOwnership');
const Proxy = artifacts.require('OwnedUpgradeabilityProxy');
const LandBaseAuthority = artifacts.require('LandBaseAuthority');
const ObjectOwnershipAuthority = artifacts.require('ObjectOwnershipAuthority');
const TokenLocationAuthority = artifacts.require('TokenLocationAuthority')
const TokenLocation = artifacts.require('TokenLocation');

const BancorConverter = artifacts.require('BancorConverter');
const BancorFormula = artifacts.require('BancorFormula');
const BancorGasPriceLimit = artifacts.require('BancorGasPriceLimit');
const EtherToken = artifacts.require('EtherToken');
const ContractFeatures = artifacts.require('ContractFeatures');
const WhiteList = artifacts.require('Whitelist');
const BancorNetwork = artifacts.require('BancorNetwork');
const BancorExchange = artifacts.require('BancorExchange');
const ContractIds = artifacts.require('ContractIds');
const FeatureIds = artifacts.require('FeatureIds');
const SmartToken = artifacts.require('SmartToken')
// const SmartTokenRING = artifacts.require('ERC223SmartToken');

const GringottsBank = artifacts.require("./GringottsBank.sol");
const BankSettingIds = artifacts.require('BankSettingIds');
const MintAndBurnAuthority = artifacts.require('MintAndBurnAuthority');

const AuctionSettingIds = artifacts.require('AuctionSettingIds');
const MysteriousTreasure = artifacts.require('MysteriousTreasure');
const GenesisHolder = artifacts.require('GenesisHolder')
const ClockAuction = artifacts.require('ClockAuction')
const RevenuePool = artifacts.require('RevenuePool');
const UserPoints = artifacts.require('UserPoints');
const UserPointsAuthority = artifacts.require('UserPointsAuthority');
const PointsRewardPool = artifacts.require('PointsRewardPool');
const BancorExchangeAuthority = artifacts.require('BancorExchangeAuthority');
const ClockAuctionAuthority = artifacts.require('ClockAuctionAuthority');


var conf = {
    registry_add: '0x6b0940772516b69088904564a56d09cfe6bb3d85',
    ring_add: '0x9469d013805bffb7d3debe5e7839237e535ec483',
    kton_add: '0x9f284e1337a815fe77d2ff4ae46544645b20c5ff',
    bankLogic_add: '0x171594fa19aa9b8caa3b02f04558f6c6198ac9fd',

}


module.exports = async() => {
    let registry = await SettingsRegistry.at(conf.registry_add);
    let bankSetting = await GringottsBank.at(conf.bankLogic_add);

    let ringId = await bankSetting.CONTRACT_RING_ERC20_TOKEN.call();
    assert.equal(await registry.addressOf(ringId), conf.ring_address);
    console.log('RING in Registry Verified！')



}