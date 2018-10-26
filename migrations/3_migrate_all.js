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
const DeployAndTest = artifacts.require('DeployAndTest');
const SmartTokenRING = artifacts.require('ERC223SmartToken');

const conf = {
    land_objectClass: 1,
    gasPrice: 10000000000,
    weight10Percent: 100000,
    from: '0x4cc4c344eba849dc09ac9af4bff1977e44fc1d7e',
}


let gold_address;
let wood_address;
let water_address;
let fire_address;
let soil_address;

let registry_address;
let ring_address;

let landBaseProxy_address;
let objectOwnershipProxy_address;
let tokenLocationProxy_address;

module.exports = async (deployer, network, accounts) => {

    // deployer.deploy(LandBaseAuthority);
    console.log("\n======================\n" +
                "LAND MIGRATION STARTS!!" +
        "\n======================\n");
    deployer.deploy(StandardERC223, "GOLD"
    ).then(async() => {
        let gold = await StandardERC223.deployed();
        gold_address = gold.address;
        return deployer.deploy(StandardERC223, "WOOD")
    }).then(async() => {
        let wood = await StandardERC223.deployed();
        wood_address = wood.address;
        return deployer.deploy(StandardERC223, "WATER")
    }).then(async() => {
        let water = await StandardERC223.deployed();
        water_address = water.address;
        return deployer.deploy(StandardERC223, "FIRE")
    }).then(async () => {
        let fire = await StandardERC223.deployed();
        fire_address = fire.address;
        return deployer.deploy(StandardERC223, "SOIL")
    }).then(async() => {
        let soil = await StandardERC223.deployed();
        soil_address = soil.address;
        await deployer.deploy(SettingIds);
        await deployer.deploy(SettingsRegistry);
        await deployer.deploy(TokenLocation);
        await deployer.deploy(Proxy);
        await deployer.deploy(LandBase)
    }).then(async () => {
        let registry = await SettingsRegistry.deployed();
        registry_address = registry.address;
        let tokenLocationProxy = await Proxy.deployed();
        tokenLocationProxy_address = tokenLocationProxy.address;
        console.log("tokenLocation proxy: ", tokenLocationProxy.address);
        return deployer.deploy(Proxy);
    }).then(async() => {
        let landBaseProxy = await Proxy.deployed();
        landBaseProxy_address = landBaseProxy.address;
        console.log("landBase proxy: ", landBaseProxy_address);
        await deployer.deploy(Proxy);
        return Proxy.deployed();
    }).then(async() => {
        await deployer.deploy(ObjectOwnership);
        let objectOwnershipProxy = await Proxy.deployed();
        objectOwnershipProxy_address = objectOwnershipProxy.address;
        console.log("objectOwnership proxy: ", objectOwnershipProxy_address);
        await deployer.deploy(ObjectOwnershipAuthority, [landBaseProxy_address]);
        await deployer.deploy(TokenLocationAuthority, [landBaseProxy_address]);
        await deployer.deploy(InterstellarEncoder);
    }).then(async () => {

        let settingIds = await SettingIds.deployed();
        let settingsRegistry = await SettingsRegistry.deployed();

        let goldId = await settingIds.CONTRACT_GOLD_ERC20_TOKEN.call();
        let woodId = await settingIds.CONTRACT_WOOD_ERC20_TOKEN.call();
        let waterId = await settingIds.CONTRACT_WATER_ERC20_TOKEN.call();
        let fireId = await settingIds.CONTRACT_FIRE_ERC20_TOKEN.call();
        let soilId = await settingIds.CONTRACT_SOIL_ERC20_TOKEN.call();

        // register resouces to registry
        await settingsRegistry.setAddressProperty(goldId, gold_address);
        await settingsRegistry.setAddressProperty(woodId, wood_address);
        await settingsRegistry.setAddressProperty(waterId, water_address);
        await settingsRegistry.setAddressProperty(fireId, fire_address);
        await settingsRegistry.setAddressProperty(soilId, soil_address);

        let interstellarEncoder = await InterstellarEncoder.deployed();
        let interstellarEncoderId = await settingIds.CONTRACT_INTERSTELLAR_ENCODER.call();
        await settingsRegistry.setAddressProperty(interstellarEncoderId, interstellarEncoder.address);

        // register in registry
        let objectOwnershipId = await settingIds.CONTRACT_OBJECT_OWNERSHIP.call();
        let landBaseId = await settingIds.CONTRACT_LAND_BASE.call();
        let tokenLocationId = await settingIds.CONTRACT_TOKEN_LOCATION.call();
        await settingsRegistry.setAddressProperty(landBaseId,landBaseProxy_address);
        await settingsRegistry.setAddressProperty(objectOwnershipId, objectOwnershipProxy_address);
        await settingsRegistry.setAddressProperty(tokenLocationId, tokenLocationProxy_address);

        console.log("REGISTER DONE!");
        // upgrade
        await Proxy.at(landBaseProxy_address).upgradeTo(LandBase.address);
        await Proxy.at(objectOwnershipProxy_address).upgradeTo(ObjectOwnership.address);
        await Proxy.at(tokenLocationProxy_address).upgradeTo(TokenLocation.address);
        console.log("UPGRADE DONE!");

        // initialize
        let tokenLocationProxy = await TokenLocation.at(tokenLocationProxy_address);
        await tokenLocationProxy.initializeContract();
        let landProxy = await LandBase.at(landBaseProxy_address);
        await landProxy.initializeContract(settingsRegistry.address);
        let objectOwnershipProxy = await ObjectOwnership.at(objectOwnershipProxy_address);
        await objectOwnershipProxy.initializeContract(settingsRegistry.address);

        console.log("INITIALIZE DONE!");
        // set authority
        await tokenLocationProxy.setAuthority(TokenLocationAuthority.address);
        await ObjectOwnership.at(objectOwnershipProxy_address).setAuthority(ObjectOwnershipAuthority.address);


        await interstellarEncoder.registerNewTokenContract(objectOwnershipProxy_address);
        await interstellarEncoder.registerNewObjectClass(landBaseProxy_address, conf.land_objectClass);

        console.log('MIGRATION SUCCESS!');
        console.log("\n======================\n" +
                    "LAND MIGRATION SUCCESS!!" +
            "\n======================\n\n");
    }).then(async() => {
        console.log("\n=======================\n" +
                    "BANCOR MIGRATION STARTS!!" +
            "\n=======================\n");
        await deployer.deploy(ContractIds);
        await deployer.deploy(SmartTokenRING);
        await deployer.deploy(ContractFeatures);
        await deployer.deploy(BancorFormula);
        await deployer.deploy(WhiteList);
        await deployer.deploy(EtherToken);
        await deployer.deploy(BancorGasPriceLimit, conf.gasPrice);
    }).then(async () => {
        let ring = await SmartTokenRING.deployed();
        ring_address = ring.address;
        let contractIds = await ContractIds.deployed();
        let settingsRegistry = await SettingsRegistry.at(registry_address);
        let contractFeaturesId = await contractIds.CONTRACT_FEATURES.call();
        await settingsRegistry.setAddressProperty(contractFeaturesId, ContractFeatures.address);
    }).then(async () => {
        await deployer.deploy(BancorConverter, ring_address, registry_address, 0, EtherToken.address, conf.weight10Percent, {gas: 8000000});
    }).then(async () => {
        await deployer.deploy(BancorExchange, BancorNetwork.address, BancorConverter.address, registry_address, {gas: 5000000});
    }).then(async () => {
        let bancorExchange = await BancorExchange.deployed();
        let settingsRegistry = await SettingsRegistry.at(registry_address);

        let whiteList = await WhiteList.deployed();
        let etherToken = await EtherToken.deployed();
        let bancorNetwork = await BancorNetwork.deployed();
        let bancorGasPriceLimit = await BancorGasPriceLimit.deployed();
        let bancorFormula = await BancorFormula.deployed();

        let contractIds = await ContractIds.deployed();

        let bancorConverter = await BancorConverter.deployed();

        // register
        let ring = await SmartTokenRING.at(ring_address);
        let ringId = await bancorExchange.CONTRACT_RING_ERC20_TOKEN.call();
        await settingsRegistry.setAddressProperty(ringId, ring_address);

        // let contractFeaturesId = await contractIds.CONTRACT_FEATURES.call();
        // await settingsRegistry.setAddressProperty(contractFeaturesId, contractFeatures.address);

        let formulaId = await contractIds.BANCOR_FORMULA.call();
        await settingsRegistry.setAddressProperty(formulaId, bancorFormula.address);
        let gasPriceLimitId = await contractIds.BANCOR_GAS_PRICE_LIMIT.call();
        await settingsRegistry.setAddressProperty(gasPriceLimitId, bancorGasPriceLimit.address);
        let bancorNetworkId = await contractIds.BANCOR_NETWORK.call();
        await settingsRegistry.setAddressProperty(bancorNetworkId, bancorNetwork.address);

        //do this to make SmartToken.totalSupply > 0
        await ring.changeCap(20 * 10**8 * COIN);
        await ring.issue(conf.from, 12 * 10 **8 * COIN);
        // await smartTokenAuthority.setWhitelist(bancorConverter.address, true);
        await ring.transferOwnership(bancorConverter.address);
        await bancorConverter.acceptTokenOwnership();

        // await etherToken.deposit({value: 1 * COIN});
        // await etherToken.transfer(BancorConverter.address, 1 * COIN);
        await bancorConverter.updateConnector(etherToken.address, 100000, true, 1200 * COIN);

        await whiteList.addAddress(bancorExchange.address);
        await bancorConverter.setConversionWhitelist(whiteList.address);

        await bancorNetwork.registerEtherToken(etherToken.address, true);

        await bancorExchange.setQuickBuyPath([etherToken.address, ring_address, ring_address]);
        await bancorExchange.setQuickSellPath([ring_address, ring_address, etherToken.address]);

        console.log('SUCCESS!')
        console.log("\n========================\n" +
                    "BANCOR MIGRATION SUCCESS!!" +
            "\n========================\n\n");
    })

}