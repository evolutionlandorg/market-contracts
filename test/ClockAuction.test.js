const utils = require('./utils/time');
const Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider);
var increaseTime = utils.increaseTime;
var increaseTimeTo = utils.increaseTimeTo;

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

const gasPrice = 30000000000000;
const weight10Percent = 100000;
const COIN = 10**18;
// 4%
const uint_auction_cut = 400;
// 30 minutes
const uint_auction_bid_waiting_time = 1800;


var registry;
var claimBountyCalculator;
var auctionSettingsId;
var mysteriousTreasure;
var genesisHolder;
var landGenesisData;
var atlantis;
var clockAuction;

// bancor related variables
var bancorConverter;
var bancorFormula;
var bancorGasPriceLimit;
var etherToken;
var ring;
var contractFeatures;
var contractRegistry;
var whiteList;
var bancorExchange;
var bancorNetwork;
var contractIds;
var featureIds;

function verifyConnector(connector, isSet, isEnabled, weight, isVirtualBalanceEnabled, virtualBalance) {
    assert.equal(connector[0], virtualBalance);
    assert.equal(connector[1], weight);
    assert.equal(connector[2], isVirtualBalanceEnabled);
    assert.equal(connector[3], isEnabled);
    assert.equal(connector[4], isSet);
}

function verifyAuctionInitial(auction, seller, startingPrice, endingPrice, duration, token, lastRecord, lastBidder, lastReferer) {
    assert.equal(auction[0], seller);
    assert.equal(auction[1], startingPrice);
    assert.equal(auction[2], endingPrice);
    assert.equal(auction[3], duration);
    assert(auction[4] > 0);
    assert.equal(auction[5], token);
    assert.equal(auction[6].valueOf(), lastRecord);
    assert.equal(auction[7], lastBidder);
    assert.equal(auction[9], lastReferer);
}

function verifyAuctionInBid(auction, seller, startingPrice, endingPrice, duration, token, lastBidder, lastReferer) {
    assert.equal(auction[0], seller);
    assert.equal(auction[1], startingPrice);
    assert.equal(auction[2], endingPrice);
    assert.equal(auction[3], duration);
    assert(auction[4] > 0);
    assert.equal(auction[5], token);
    assert(auction[6] > 0);
    assert.equal(auction[7], lastBidder);
    assert(auction[8] > 0);
    assert.equal(auction[9], lastReferer);
}

async function initBancor(accounts) {
    let contractFeaturesId;
    let gasPriceLimitId;
    let formulaId;
    let bancorNetworkId;

    contractRegistry = await ContractRegistry.new();
    console.log('contractRegistry address: ', contractRegistry.address);

    contractIds = await ContractIds.new();

    contractFeatures = await ContractFeatures.new();
    contractFeaturesId = await contractIds.CONTRACT_FEATURES.call();
    await contractRegistry.registerAddress(contractFeaturesId, contractFeatures.address);
    console.log('contractFeatures address: ', contractFeatures.address);

    bancorFormula = await BancorFormula.new();
    formulaId = await contractIds.BANCOR_FORMULA.call();
    await contractRegistry.registerAddress(formulaId, bancorFormula.address);
    console.log('bancorFormula address: ', bancorFormula.address);

    bancorGasPriceLimit = await BancorGasPriceLimit.new(gasPrice);
    gasPriceLimitId = await contractIds.BANCOR_GAS_PRICE_LIMIT.call();
    await contractRegistry.registerAddress(gasPriceLimitId, bancorGasPriceLimit.address);
    console.log('bancorGasPriceLimit address: ', bancorGasPriceLimit.address);

    featureIds = await FeatureIds.new();
    console.log('featureIds address: ', featureIds.address);

    whiteList = await WhiteList.new();
    console.log('whiteList address: ', whiteList.address);

    etherToken = await EtherToken.new();
    console.log('etherToken address: ', etherToken.address);

    ring = await RING.new("RING");
    console.log('ring address: ', ring.address);

    // more complex
    bancorNetwork = await BancorNetwork.new(contractRegistry.address);
    bancorNetworkId = await contractIds.BANCOR_NETWORK.call();
    await contractRegistry.registerAddress(bancorNetworkId, bancorNetwork.address);

    bancorConverter = await BancorConverter.new(ring.address, contractRegistry.address, 0, etherToken.address, weight10Percent);
    console.log('bancorConverter address: ', bancorConverter.address);

    bancorExchange = await BancorExchange.new(ring.address, bancorNetwork.address, bancorConverter.address);
    console.log('bancorExchange address: ', bancorExchange.address);

    //do this to make SmartToken.totalSupply > 0
    await ring.issue(accounts[0], 1000000 * COIN);
    await ring.setOwner(bancorConverter.address);

    await etherToken.deposit({value: 1 * COIN});
    await etherToken.transfer(bancorConverter.address, 1 * COIN);

    await whiteList.addAddress(bancorExchange.address);
    await bancorConverter.setConversionWhitelist(whiteList.address);

    await bancorNetwork.registerEtherToken(etherToken.address, true);

    await bancorExchange.setQuickBuyPath([etherToken.address, ring.address, ring.address]);
    await bancorExchange.setQuickSellPath([ring.address, ring.address, etherToken.address]);
}



// contract('bancor deployment', async(accounts) => {
//
//     before('deploy and configure', async() => {
//         await initBancor(accounts);
//     })
//
//     it('verify configuration in contractRegistry', async() => {
//         // check registry
//         let contractFeaturesInRegistry = await contractRegistry.addressOf(await contractIds.CONTRACT_FEATURES.call());
//         assert.equal(contractFeaturesInRegistry, contractFeatures.address);
//
//         let bancorGasPriceLimitInRegistry = await contractRegistry.addressOf(await contractIds.BANCOR_GAS_PRICE_LIMIT.call());
//         assert.equal(bancorGasPriceLimitInRegistry, bancorGasPriceLimit.address);
//
//         let bancorFormulaInRegistry = await contractRegistry.addressOf(await contractIds.BANCOR_FORMULA.call());
//         assert.equal(bancorFormulaInRegistry, bancorFormula.address);
//
//         let bancorNetworkInRegistry = await contractRegistry.addressOf(await contractIds.BANCOR_NETWORK.call());
//         assert.equal(bancorNetworkInRegistry, bancorNetwork.address);
//
//     })
//
//     it('bancorConverter related checks', async () => {
//
//         assert.equal(await bancorConverter.token(), ring.address);
//         // smartToken's owner
//         assert.equal(await ring.owner(), bancorConverter.address);
//         // whitelist
//         assert.equal(await bancorConverter.conversionWhitelist(), whiteList.address);
//         // registry
//         let registryInConverter = await bancorConverter.registry();
//         assert.equal(registryInConverter, contractRegistry.address);
//         // check connector balance
//         assert.equal(await etherToken.balanceOf(bancorConverter.address), 10**18);
//         let connecorBalance = await bancorConverter.getConnectorBalance(etherToken.address);
//         assert(connecorBalance.valueOf() > 0);
//         let supply = await ring.totalSupply();
//         assert(supply.valueOf() > 0);
//
//         let featureWhitelist = await bancorConverter.CONVERTER_CONVERSION_WHITELIST.call();
//         let isSupported = await contractFeatures.isSupported.call(bancorConverter.address, featureWhitelist);
//         assert(isSupported);
//
//         let maxConversionFee = await bancorConverter.maxConversionFee.call();
//         assert.equal(maxConversionFee, 0);
//         let conversionsEnabled = await bancorConverter.conversionsEnabled.call();
//         assert.equal(conversionsEnabled, true);
//
//         let connector = await bancorConverter.connectors(etherToken.address);
//         verifyConnector(connector, true, true, 100000, false, 0);
//
//         let amount = await bancorConverter.getPurchaseReturn(etherToken.address, 10**18);
//         console.log('buy amount: ', amount.valueOf());
//
//         let amount1 = await bancorConverter.getReturn(etherToken.address, ring.address, 10**18);
//         console.log('getReturn: ', amount1.valueOf());
//         assert.equal(amount.valueOf(), amount1.valueOf());
//
//     })
//
//     it('bancorNetwork related checks', async () => {
//         assert(await contractFeatures.isSupported(bancorConverter.address, await featureIds.CONVERTER_CONVERSION_WHITELIST.call()));
//         assert(await whiteList.isWhitelisted(bancorExchange.address));
//         assert(await bancorNetwork.etherTokens(etherToken.address));
//         let registryInNetwork = await bancorNetwork.registry();
//         assert.equal(registryInNetwork, contractRegistry.address);
//         // connctor number
//         let count = await bancorConverter.connectorTokenCount();
//         assert.equal(count, 1);
//
//     })
//
//     it('bancorExchange related checks', async () => {
//         let et = await bancorExchange.quickBuyPath(0);
//         assert.equal(et, etherToken.address);
//         assert.equal(ring.address, await bancorExchange.quickBuyPath(1));
//         assert.equal(ring.address, await bancorExchange.quickBuyPath(2));
//
//         let st = await bancorExchange.quickSellPath(0);
//         assert.equal(st, ring.address);
//         assert.equal(st, await bancorExchange.quickSellPath(1));
//         assert.equal(etherToken.address, await bancorExchange.quickSellPath(2));
//
//     })
//
//     it('buy rings', async() => {
//         let amount = await bancorExchange.buyRING(1, {from: accounts[1], value: 10 ** 18});
//         let ringBalanceOfAccount1 = await ring.balanceOf(accounts[1]);
//         // console.log('amount from exchange: ', amount.valueOf());
//         console.log('balance in ring of account1: ', ringBalanceOfAccount1.valueOf());
//     })
//
//
// })

contract('ClockAuction deployment', async(accounts) => {

    let firstBidRecord;
    let secondBidRebcord;

    before('deploy series contracts', async () => {
        await initBancor(accounts);

        registry = await SettingsRegistry.new();
        let auth_string = await registry.ROLE_AUTH_CONTROLLER.call();
        await registry.adminAddRole(accounts[0], auth_string);
        console.log('registry address: ', registry.address);

        auctionSettingsId = await AuctionSettingIds.new();
        console.log('auctionSettingIds address: ', auctionSettingsId.address);

        atlantis = await Atlantis.new();
        console.log('atlantis address: ', atlantis.address);

        mysteriousTreasure = await MysteriousTreasure.new(registry.address, [10439, 419, 5258, 12200, 12200]);
        console.log('mysteriousTreasure address: ', mysteriousTreasure.address);

        genesisHolder = await GenesisHolder.new(registry.address, ring.address);
        console.log('genesisHolder address: ', genesisHolder.address);

        claimBountyCalculator = await ClaimBountyCalculator.new();
        console.log('claimBountyCalculator address: ', claimBountyCalculator.address);

        landGenesisData = await LandGenesisData.new();
        console.log('landGenesisData address: ', landGenesisData.address);

        // register addresses part
        let ringId = await auctionSettingsId.CONTRACT_RING_ERC20_TOKEN.call();
        await registry.setAddressProperty(ringId, ring.address);
        console.log('ringId: ', ringId);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_AUCTION_CLAIM_BOUNTY.call(), claimBountyCalculator.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_MYSTERIOUS_TREASURE.call(), mysteriousTreasure.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_BANCOR_EXCHANGE.call(), bancorExchange.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_ATLANTIS_ERC721LAND.call(), atlantis.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_LAND_DATA.call(), landGenesisData.address);
        // register uint
        await registry.setUintProperty(await auctionSettingsId.UINT_AUCTION_CUT.call(), uint_auction_cut);
        await registry.setUintProperty(await auctionSettingsId.UINT_AUCTION_BID_WAITING_TIME.call(), uint_auction_bid_waiting_time);

        await landGenesisData.adminAddRole(mysteriousTreasure.address, await landGenesisData.ROLE_ADMIN.call());

        clockAuction = await ClockAuction.new(atlantis.address, genesisHolder.address, registry.address);
        console.log('clockAuction address: ', clockAuction.address);

        await mysteriousTreasure.transferOwnership(clockAuction.address);
        await registry.setAddressProperty(await auctionSettingsId.CONTRACT_CLOCK_AUCTION.call(), clockAuction.address);
    })

    it('assign new land', async() => {
        await atlantis.assignNewLand(-101, 12, accounts[0]);
        console.log('0x' + (await atlantis.tokenOfOwnerByIndex(accounts[0], 0)).toString(16));
        // assgin new land to genesis holder
        await atlantis.assignNewLand(-98, 5, genesisHolder.address);
        console.log('0x' + (await atlantis.encodeTokenId(-98, 5)).toString(16));
    })

    it('create an auction', async() => {
        let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(accounts[0], 0)).toString(16);
        await atlantis.approveAndCall(clockAuction.address, tokenId,
            '0x00000000000000000000000000000000000000000000152d02c7e14af6800000000000000000000000000000000000000000000000000a968163f0a57b400000000000000000000000000000000000000000000000000000000000000000012c00000000000000000000000089f590313Aa830C5bda128c76d49ddE89C9C831a');
        // token's owner change to clockAuction
        let owner = await atlantis.ownerOf(tokenId);
        assert.equal(owner, clockAuction.address);

        let auction1 = await clockAuction.getAuction(tokenId);
        verifyAuctionInitial(auction1, accounts[0], 100000 * COIN, 50000 * COIN, 300, ring.address, 0, 0, 0);
    })

    it('bid for auction', async() => {
        let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(clockAuction.address, 0)).toString(16);
        console.log('tokenId in auction: ', tokenId);
        assert((await ring.balanceOf(accounts[0])).valueOf() > 100000 * COIN);
       // await RING.at(ring.address).contract.transfer['address,uint256,bytes'](accounts[1], 10 * 10**18, '0x0c', {from: accounts[0], gas: 300000});
        await RING.at(ring.address).contract.transfer['address,uint256,bytes'](clockAuction.address, 100000 * COIN, '0xffffffffffffffffffffffffffffff9b0000000000000000000000000000000c00000000000000000000000002A98FDb710Ea5611423cC1a62c0d6ecF88A4E2E', {from: accounts[0], gas:3000000});
        console.log('balanceof clockauction: ', await ring.balanceOf(clockAuction.address));
        let auction = await clockAuction.getAuction(tokenId);
        firstBidRecord = auction[6];
        verifyAuctionInBid(auction, accounts[0], 100000 * COIN, 50000 * COIN, 300, ring.address, accounts[0], accounts[1]);
    })

    it('bid with eth', async () => {
        let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(clockAuction.address, 0)).toString(16);
        let ringBalancePrev0 = await ring.balanceOf(accounts[0]);

        await clockAuction.bidWithETH(tokenId, accounts[3], {from: accounts[2], value: 2 * COIN});
        let auction = await clockAuction.getAuction(tokenId);
        secondBidRebcord = auction[6];
        verifyAuctionInBid(auction, accounts[0], 100000 * COIN, 50000 * COIN, 300, ring.address, accounts[2], accounts[3]);
        // require (lastrecord * 1.1 = thisrecord)
        assert.equal(firstBidRecord * 1.1, secondBidRebcord);
        let ringBalanceNow0 = await ring.balanceOf(accounts[0]);
        assert(ringBalanceNow0.toNumber() > ringBalancePrev0.toNumber());
    })

    it('claim land asset', async () => {
        let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(clockAuction.address, 0)).toString(16);
        assert.equal(await atlantis.ownerOf(tokenId), clockAuction.address);
        console.log('token owner confirmed!')
        let expireTime = ((await clockAuction.getAuction(tokenId))[8]).toNumber() + uint_auction_bid_waiting_time;
        console.log('expire time: ', expireTime);
        let  now = (await web3.eth.getBlock("latest")).timestamp;
        console.log('now: ', now);
        await increaseTime(uint_auction_bid_waiting_time);
        let increasedTime = (await web3.eth.getBlock("latest")).timestamp;
        console.log('time after increasion: ', increasedTime);
        assert((increasedTime - expireTime) >= 0, 'time increasion failed!')
        assert.equal(await mysteriousTreasure.owner(), clockAuction.address, 'mysterious owner is not auction');

        let newOwner = (await clockAuction.getAuction(tokenId))[7];
        assert.equal(newOwner, accounts[2], 'new owner is now lastbidder');

        console.log('has box in landdata: ', await landGenesisData.hasBox(tokenId));


        await clockAuction.claimLandAsset(tokenId, {from: accounts[3]});
        // let owner = await atlantis.ownerOf(tokenId);
        // // assert.equal(owner, accounts[2]);
        // console.log('owner: ', owner);

    })




})

