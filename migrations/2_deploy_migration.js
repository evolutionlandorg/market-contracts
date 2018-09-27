const SettingsRegistry = artifacts.require('SettingsRegistry');
const ClaimBountyCalculator = artifacts.require('ClaimBountyCalculator');
const AuctionSettingIds = artifacts.require('AuctionSettingIds');
const MysteriousTreasure = artifacts.require('MysteriousTreasure');
const GenesisHolder = artifacts.require('GenesisHolder')
const LandGenesisData = artifacts.require('LandGenesisData');
const Atlantis = artifacts.require('Atlantis');
const ClockAuction = artifacts.require('ClockAuction')

// bancor related
const RING = artifacts.require('StandardERC223');
const BancorConverter = artifacts.require('BancorConverter');
const BancorFormula = artifacts.require('BancorFormula');
const BancorGasPriceLimit = artifacts.require('BancorGasPriceLimit');
const EtherToken = artifacts.require('EtherToken');
const ContractFeatures = artifacts.require('ContractFeatures');
const ContractRegistry = artifacts.require('ContractRegistry');
const WhiteList = artifacts.require('Whitelist');
const BancorNetwork = artifacts.require('BancorNetwork');
const BancorExchange = artifacts.require('BancorExchange');
const ContractIds = artifacts.require('ContractIds');
const FeatureIds = artifacts.require('FeatureIds');

var BancorAddress = {
    ContractRegistry: '0x3d53a3fa6f8ceb8406646c3e8c998a70ee1bb0dd',
    ContractIds: '0x1d29342f6280c7016e847b9040b43208f930dc3a',
    ContractFeatures: '0x42ba40709deb1290ab29e256c9ede32d8907702c',
    BancorFormula: '0xff654eb1a520756d5fdc356b935c8b5502fb208a',
    Whitelist: '0x1c452d1803270d46b6ece2d07b71472a3d2967b8',
    BancorGasPriceLimit: '0x50cf1e6f96570f5bc4be6ed56b6dbcba0cb48e00',
    EtherToken: '0x5e573d9e960c83ab0c081e0935780e5320c37ead',
    RING: '0x85eecffd2495c7d9246b038ee33f2038d17a2080',
    BancorNetwork: '0xac6e1bed550a16faeca8ed2b3fffe852942f9ac1',
    BancorConverter: '0xccdbe8b0676a363e1b599a8cd92397dac2e4c5a7',
    BancorExchange: '0xcff38186b30df6922423071ed3878c61c3d07bf5'
}

var AuctionConf = {
    // 4%
   uint_auction_cut: 400,
    // 30 minutes
    uint_auction_bid_waiting_time: 1800,
    from: '0x4cc4c344eba849dc09ac9af4bff1977e44fc1d7e'
}

module.exports = function(deployer) {
    deployer.deploy(SettingsRegistry);
    deployer.deploy(AuctionSettingIds);
    deployer.deploy(Atlantis);
    deployer.deploy(ClaimBountyCalculator);
    deployer.deploy(LandGenesisData).then( async() => {
        let ring = await RING.at(BancorAddress.RING);
        let registry = await SettingsRegistry.deployed();

        await deployer.deploy(MysteriousTreasure,registry.address, [10439, 419, 5258, 12200, 12200]);
        await deployer.deploy(GenesisHolder,registry.address, ring.address);

        let auth_string = await registry.ROLE_AUTH_CONTROLLER.call();
        await registry.adminAddRole(AuctionConf.from, auth_string);

        let auctionSettingsId = await AuctionSettingIds.deployed();

        // registry address in SettingsRegistry
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_RING_ERC20_TOKEN.call(), ring.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_AUCTION_CLAIM_BOUNTY.call(), ClaimBountyCalculator.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_MYSTERIOUS_TREASURE.call(), MysteriousTreasure.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_BANCOR_EXCHANGE.call(), BancorAddress.BancorExchange);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_ATLANTIS_ERC721LAND.call(), Atlantis.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_LAND_DATA.call(), LandGenesisData.address);
        // register uint
        await registry.setUintProperty(await auctionSettingsId.UINT_AUCTION_CUT.call(), AuctionConf.uint_auction_cut);
        await registry.setUintProperty(await auctionSettingsId.UINT_AUCTION_BID_WAITING_TIME.call(), AuctionConf.uint_auction_bid_waiting_time);

        let mysteriousTreasure = await MysteriousTreasure.deployed();
        let landGenesisData = await LandGenesisData.deployed();
        await landGenesisData.adminAddRole(mysteriousTreasure.address, await landGenesisData.ROLE_ADMIN.call());

        await deployer.deploy(ClockAuction, Atlantis.address, GenesisHolder.address, registry.address);

        await mysteriousTreasure.transferOwnership(ClockAuction.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_CLOCK_AUCTION.call(), ClockAuction.address);

        console.log('SUCESS! ');
    })
}





