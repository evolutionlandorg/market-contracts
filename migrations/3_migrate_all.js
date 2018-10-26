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

const COIN = 10**18;


const conf = {
    land_objectClass: 1,
    gasPrice: 10000000000,
    weight10Percent: 100000,
    bank_unit_interest: 1000,
    bank_penalty_multiplier: 3,
    // 4%
    uint_auction_cut: 400,
    // 20%
    uint_referer_cut: 2000,
    // 30 minutes
    uint_bid_waiting_time: 1800,
    // errorsparce
    uint_error_space: 0,
    from: '0x4cc4c344eba849dc09ac9af4bff1977e44fc1d7e',
    contribution_incentive_address: '0x4cc4c344eba849dc09ac9af4bff1977e44fc1d7e',
    dev_pool_address: '0x4cc4c344eba849dc09ac9af4bff1977e44fc1d7e',
    dividends_pool_address: '0x4cc4c344eba849dc09ac9af4bff1977e44fc1d7e'
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

let clockAuctionProxy_address;
let mysteriousTreasureProxy_address;
let genesisHolderProxy_address;
let revenuePoolProxy_address;
let pointsRewardPoolProxy_address;
let userPointsProxy_address;

module.exports = async (deployer, network, accounts) => {

    if(network != "development") {
        return;
    }

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

    }).then(async() => {
        console.log("\n======================\n" +
            "LAND MIGRATION SUCCESS!!" +
            "\n======================\n\n");
    }).then(async() => {
        console.log("\n=======================\n" +
                    "BANCOR MIGRATION STARTS!!" +
            "\n=======================\n");
        await deployer.deploy(ContractIds);
        await deployer.deploy(StandardERC223,"RING");
        await deployer.deploy(ContractFeatures);
        await deployer.deploy(BancorFormula);
        await deployer.deploy(WhiteList);
        await deployer.deploy(EtherToken);
        await deployer.deploy(BancorGasPriceLimit, conf.gasPrice);
        await deployer.deploy(BancorNetwork, registry_address);
    }).then(async () => {
        let ring = await StandardERC223.deployed();
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
        let ring = await StandardERC223.at(ring_address);
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
        // await ring.changeCap(20 * 10**8 * COIN);
        await ring.issue(conf.from, 12 * 10 **8 * COIN);
        // await smartTokenAuthority.setWhitelist(bancorConverter.address, true);
        // await ring.transferOwnership(bancorConverter.address);
        // await bancorConverter.acceptTokenOwnership();
        await ring.setOwner(BancorConverter.address);

        // await etherToken.deposit({value: 1 * COIN});
        // await etherToken.transfer(BancorConverter.address, 1 * COIN);
        await bancorConverter.updateConnector(etherToken.address, 100000, true, 1200 * COIN);

        await whiteList.addAddress(bancorExchange.address);
        await bancorConverter.setConversionWhitelist(whiteList.address);

        await bancorNetwork.registerEtherToken(etherToken.address, true);

        await bancorExchange.setQuickBuyPath([etherToken.address, ring_address, ring_address]);
        await bancorExchange.setQuickSellPath([ring_address, ring_address, etherToken.address]);

        console.log('SUCCESS!')

    }).then(async() => {
        console.log("\n========================\n" +
            "BANCOR MIGRATION SUCCESS!!" +
            "\n========================\n\n");
    }).then(async() => {
        console.log("\n========================\n" +
            "BANK MIGRATION STARTS!!" +
            "\n========================\n\n");
        await deployer.deploy(BankSettingIds);
        await deployer.deploy(StandardERC223, 'KTON');
        await deployer.deploy(Proxy);
        await deployer.deploy(GringottsBank);
    }).then(async () => {
        return deployer.deploy(MintAndBurnAuthority, [Proxy.address]);
    }).then(async() => {

        let registry = await SettingsRegistry.at(registry_address);
        let settingIds = await BankSettingIds.deployed();
        let kton  =  await StandardERC223.deployed();

        // register in registry
        let ktonId = await settingIds.CONTRACT_KTON_ERC20_TOKEN.call();
        await registry.setAddressProperty(ktonId, kton.address);

        let bank_unit_interest = await settingIds.UINT_BANK_UNIT_INTEREST.call();
        await registry.setUintProperty(bank_unit_interest, conf.bank_unit_interest);

        let bank_penalty_multiplier = await settingIds.UINT_BANK_PENALTY_MULTIPLIER.call();
        await registry.setUintProperty(bank_penalty_multiplier, conf.bank_penalty_multiplier);
        console.log("REGISTRATION DONE! ");

        // upgrade
        let proxy = await Proxy.deployed();
        console.log('proxy address', proxy.address);
        await proxy.upgradeTo(GringottsBank.address);
        console.log("UPGRADE DONE! ");

        // initialize
        let bankProxy = await GringottsBank.at(Proxy.address);
        await bankProxy.initializeContract(registry_address);
        console.log("INITIALIZATION DONE! ");

        // setAuthority to kton
        await kton.setAuthority(MintAndBurnAuthority.address);

        console.log('MIGRATION SUCCESS!');


        // kton.setAuthority will be done in market's migration
        let interest = await bankProxy.computeInterest.call(10000, 12, conf.bank_unit_interest);
        console.log("Current annual interest for 10000 RING is: ... " + interest + " KTON");

        console.log("\n======================\n" +
            "BANK MIGRATION SUCCESS!!" +
            "\n======================\n\n");
    }).then(async() => {
        console.log("\n========================\n" +
            "AUCTION MIGRATION STARTS!!" +
            "\n========================\n\n");
        await deployer.deploy(AuctionSettingIds);
        await deployer.deploy(Proxy)
    }).then(async () => {
        let clockAuctionProxy = await Proxy.deployed();
        clockAuctionProxy_address = clockAuctionProxy.address;
        console.log("ClockAuctionProxy_address: ", clockAuctionProxy_address);
        await deployer.deploy(ClockAuction);
        return deployer.deploy(Proxy);
    }).then(async () => {
        let mysteriousTreasureProxy = await Proxy.deployed();
        mysteriousTreasureProxy_address = mysteriousTreasureProxy.address;
        console.log("mysteriousTreasureProxy_address: ", mysteriousTreasureProxy_address);
        await deployer.deploy(MysteriousTreasure);
        return deployer.deploy(Proxy)
    }).then(async () => {
        let genesisHolderProxy  = await Proxy.deployed();
        genesisHolderProxy_address = genesisHolderProxy.address;
        console.log("genesisHolderProxy_address: ", genesisHolderProxy_address);
        await deployer.deploy(GenesisHolder);
        return deployer.deploy(Proxy)
    }).then(async () => {
        let revenuePoolProxy = await Proxy.deployed();
        revenuePoolProxy_address = revenuePoolProxy.address;
        console.log("revenuePoolProxy_address: ", revenuePoolProxy_address);
        await deployer.deploy(RevenuePool);
        return deployer.deploy(Proxy)
    }).then(async() => {
        let pointsRewardPoolProxy = await Proxy.deployed();
        pointsRewardPoolProxy_address = pointsRewardPoolProxy.address;
        console.log("pointsRewardPoolProxy_address: ", pointsRewardPoolProxy_address);
        await deployer.deploy(PointsRewardPool);
        return deployer.deploy(Proxy)
    }).then(async() => {
        let userPointsProxy = await Proxy.deployed();
        userPointsProxy_address = userPointsProxy.address;
        console.log("userPoints Proxy address: ", userPointsProxy_address);
        await deployer.deploy(UserPoints);
    }).then(async() => {
        await deployer.deploy(UserPointsAuthority, [revenuePoolProxy_address, pointsRewardPoolProxy_address]);
        await deployer.deploy(LandBaseAuthority, [mysteriousTreasureProxy_address]);
        await deployer.deploy(BancorExchangeAuthority, [clockAuctionProxy_address]);
        await deployer.deploy(ClockAuctionAuthority, [genesisHolderProxy_address]);
    }).then(async () => {

        // let ring = await RING.at(conf.ring_address);
        let registry = await SettingsRegistry.at(registry_address);
        let settingIds = await AuctionSettingIds.deployed();

        //register to registry

        let revenueId = await settingIds.CONTRACT_REVENUE_POOL.call();
        await registry.setAddressProperty(revenueId, revenuePoolProxy_address);

        let pointsRewardId = await settingIds.CONTRACT_POINTS_REWARD_POOL.call();
        await registry.setAddressProperty(pointsRewardId, pointsRewardPoolProxy_address);

        let userPointsId = await settingIds.CONTRACT_USER_POINTS.call();
        await registry.setAddressProperty(userPointsId, userPointsProxy_address);

        let contributionId = await settingIds.CONTRACT_CONTRIBUTION_INCENTIVE_POOL.call();
        await registry.setAddressProperty(contributionId, conf.contribution_incentive_address);

        let dividendsId = await settingIds.CONTRACT_DIVIDENDS_POOL.call();
        await registry.setAddressProperty(dividendsId, conf.dividends_pool_address);

        let devId = await settingIds.CONTRACT_DEV_POOL.call();
        await registry.setAddressProperty(devId, conf.dev_pool_address);

        let ringId = await settingIds.CONTRACT_RING_ERC20_TOKEN.call();
        await registry.setAddressProperty(ringId, ring_address);

        let auctionId = await settingIds.CONTRACT_CLOCK_AUCTION.call();
        await registry.setAddressProperty(auctionId, clockAuctionProxy_address);

        let auctionCutId = await settingIds.UINT_AUCTION_CUT.call();
        await registry.setUintProperty(auctionCutId, conf.uint_auction_cut);

        let waitingTimeId = await settingIds.UINT_AUCTION_BID_WAITING_TIME.call();
        await registry.setUintProperty(waitingTimeId, conf.uint_bid_waiting_time);

        let treasureId = await settingIds.CONTRACT_MYSTERIOUS_TREASURE.call();
        await registry.setAddressProperty(treasureId, mysteriousTreasureProxy_address);

        let bancorExchangeId = await settingIds.CONTRACT_BANCOR_EXCHANGE.call();
        await registry.setAddressProperty(bancorExchangeId, BancorExchange.address);

        let refererCutId = await settingIds.UINT_REFERER_CUT.call();
        await registry.setUintProperty(refererCutId, conf.uint_referer_cut);

        let errorSpaceId = await settingIds.UINT_EXCHANGE_ERROR_SPACE.call();
        await registry.setUintProperty(errorSpaceId, conf.uint_error_space);

        console.log("REGISTRATION DONE! ");

        // upgrade
        await Proxy.at(clockAuctionProxy_address).upgradeTo(ClockAuction.address);
        await Proxy.at(mysteriousTreasureProxy_address).upgradeTo(MysteriousTreasure.address);
        await Proxy.at(genesisHolderProxy_address).upgradeTo(GenesisHolder.address);
        await Proxy.at(revenuePoolProxy_address).upgradeTo(RevenuePool.address);
        await Proxy.at(pointsRewardPoolProxy_address).upgradeTo(PointsRewardPool.address);
        await Proxy.at(userPointsProxy_address).upgradeTo(UserPoints.address);
        console.log("UPGRADE DONE! ");

        // initialize
        let clockAuctionProxy = await ClockAuction.at(clockAuctionProxy_address);
        await clockAuctionProxy.initializeContract(registry_address);

        let genesisHolderProxy = await GenesisHolder.at(genesisHolderProxy_address);
        await genesisHolderProxy.initializeContract(registry_address);

        let mysteriousTreasureProxy = await MysteriousTreasure.at(mysteriousTreasureProxy_address);
        await mysteriousTreasureProxy.initializeContract(registry_address, [10439, 419, 5258, 12200, 12200]);

        let revenuePoolProxy = await RevenuePool.at(revenuePoolProxy_address);
        await revenuePoolProxy.initializeContract(registry_address);

        let pointsRewardPoolProxy = await PointsRewardPool.at(pointsRewardPoolProxy_address);
        await pointsRewardPoolProxy.initializeContract(registry_address);

        let userPointsProxy = await UserPoints.at(userPointsProxy_address);
        await userPointsProxy.initializeContract();
        console.log("INITIALIZATION DONE! ");

        // allow treasure to modify data in landbase
        let landBaseProxy = await LandBase.at(landBaseProxy_address);
        await landBaseProxy.setAuthority(LandBaseAuthority.address);

        // transfer treasure's owner to clockAuction
        await mysteriousTreasureProxy.setOwner(clockAuctionProxy_address);

        // set authority
        await userPointsProxy.setAuthority(UserPointsAuthority.address);
        await BancorExchange.at(BancorExchange.address).setAuthority(BancorExchangeAuthority.address);

        await clockAuctionProxy.setAuthority(ClockAuctionAuthority.address);

        console.log("MIGRATE SUCCESSFULLY! ")

        console.log("\n========================\n" +
            "AUCTION MIGRATION SUCCESS!!" +
            "\n========================\n\n");

    })

}