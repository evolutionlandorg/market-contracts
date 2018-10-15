
const BancorInitialization = require('./BancorInitial');
var initBancor = BancorInitialization.initBancor;

const StandardERC223 = artifacts.require('StandardERC223');
const SettingsRegistry = artifacts.require('SettingsRegistry');
const ClaimBountyCalculator = artifacts.require('ClaimBountyCalculator');
const AuctionSettingIds = artifacts.require('AuctionSettingIds');
const MysteriousTreasure = artifacts.require('MysteriousTreasure');
const GenesisHolder = artifacts.require('GenesisHolder')
const LandBase = artifacts.require('LandBase');
const ObjectOwnership = artifacts.require('ObjectOwnership');
const ClockAuction = artifacts.require('ClockAuction');

const COIN = 10**18;
// 4%
const uint_auction_cut = 400;
// 30 minutes
const uint_auction_bid_waiting_time = 1800;

// 20%
const uint_referer_cut = 2000;

module.exports = {
    initClockAuction: initClockAuction
}

// TODO: setAddressProperty for gold, wood, water, fire, and soil.

async function initClockAuction(accounts) {
    let initial = await initBancor(accounts);
    let ring = initial.ring;
    let bancorExchange = initial.bancorExchange;

    let registry = await SettingsRegistry.new();
    let auth_string = await registry.ROLE_AUTH_CONTROLLER.call();
    await registry.adminAddRole(accounts[0], auth_string);
    console.log('registry address: ', registry.address);

    let auctionSettingsId = await AuctionSettingIds.new();
    console.log('auctionSettingIds address: ', auctionSettingsId.address);

    let objectOwnership = await ObjectOwnership.new();
    console.log('objectOwnership address: ', objectOwnership.address);

    let mysteriousTreasure = await MysteriousTreasure.new(registry.address, [10439, 419, 5258, 12200, 12200]);
    console.log('mysteriousTreasure address: ', mysteriousTreasure.address);

    let genesisHolder = await GenesisHolder.new(registry.address, ring.address);
    console.log('genesisHolder address: ', genesisHolder.address);
    await genesisHolder.setOperator(accounts[1]);

    let claimBountyCalculator = await ClaimBountyCalculator.new();
    console.log('claimBountyCalculator address: ', claimBountyCalculator.address);

    let landBase = await LandBase.new();
    console.log('landBase address: ', landBase.address);

    // register addresses part
    let ringId = await auctionSettingsId.CONTRACT_RING_ERC20_TOKEN.call();
    await registry.setAddressProperty(ringId, ring.address);

    await registry.setAddressProperty(await auctionSettingsId.CONTRACT_AUCTION_CLAIM_BOUNTY.call(), claimBountyCalculator.address);
    await registry.setAddressProperty(await auctionSettingsId.CONTRACT_MYSTERIOUS_TREASURE.call(), mysteriousTreasure.address);
    await registry.setAddressProperty(await auctionSettingsId.CONTRACT_BANCOR_EXCHANGE.call(), bancorExchange.address);
    await registry.setAddressProperty(await auctionSettingsId.CONTRACT_TOKEN_OWNERSHIP.call(), objectOwnership.address);
    await registry.setAddressProperty(await auctionSettingsId.CONTRACT_LAND_BASE.call(), landBase.address);
    // register uint
    await registry.setUintProperty(await auctionSettingsId.UINT_AUCTION_CUT.call(), uint_auction_cut);
    await registry.setUintProperty(await auctionSettingsId.UINT_AUCTION_BID_WAITING_TIME.call(), uint_auction_bid_waiting_time);
    await registry.setUintProperty(await auctionSettingsId.UINT_REFERER_CUT.call(), uint_referer_cut);

    await landBase.adminAddRole(mysteriousTreasure.address, await landGenesisData.ROLE_ADMIN.call());

    let clockAuction = await ClockAuction.new(objectOwnership.address, genesisHolder.address, registry.address);
    console.log('clockAuction address: ', clockAuction.address);

    await mysteriousTreasure.transferOwnership(clockAuction.address);
    await registry.setAddressProperty(await auctionSettingsId.CONTRACT_CLOCK_AUCTION.call(), clockAuction.address);

    let kton = await StandardERC223.new('KTON');
    console.log("Kton address: ", kton.address);

    return {
        clockAuction: clockAuction,
        objectOwnership: objectOwnership,
        ring: ring,
        genesisHolder:genesisHolder,
        landBase: landBase,
        kton: kton
    }
}