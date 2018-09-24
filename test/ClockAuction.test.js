
const SettingsRegistry = artifacts.require('SettingsRegistry');
const RING = artifacts.require('StandardERC223');
const ClaimBountyCalculator = artifacts.require('ClaimBountyCalculator');
const AuctionSettingIds = artifacts.require('AuctionSettingIds');
const MysteriousTreasure = artifacts.require('MysteriousTreasure');
const GenesisHolder = artifacts.require('GenesisHolder')
const LandGenesisData = artifacts.require('LandGenesisData');
const Atlantis = artifacts.require('Atlantis');
// bancor related
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

const gasPrice = 30000000000;

const weight10Percent = 100000;


var registry;
var ring;
var claimBountyCalculator;
var auctionSettingsId;
var mysteriousTreasure;
var genesisHolder;
var landGenesisData;
var atlantis;

// bancor related variables
var bancorConverter;
var bancorFormula;
var bancorGasPriceLimit;
var etherToken;
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



contract('bancor deployment', async(accounts) => {
    let contractFeaturesId;
    let gasPriceLimitId;
    let formulaId;
    let bancorNetworkId;

    before('deploy and configure', async() => {
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
        console.log('bancorFormula address: ', bancorFormula);

        bancorGasPriceLimit = await BancorGasPriceLimit.new(gasPrice);
        gasPriceLimitId = await contractIds.BANCOR_GAS_PRICE_LIMIT.call();
        await contractRegistry.registerAddress(gasPriceLimitId, bancorGasPriceLimit.address);
        console.log('bancorGasPriceLimit address: ', bancorGasPriceLimit.address);

        featureIds = await FeatureIds.new({from: accounts[0]});
        console.log('featureIds address: ', featureIds.address);

        whiteList = await WhiteList.new({from: accounts[0]});
        console.log('whiteList address: ', whiteList.address);

        etherToken = await EtherToken.new({from: accounts[0]});
        console.log('etherToken address: ', etherToken.address);

        ring = await RING.new("RING",{from: accounts[0]});
        console.log('ring address: ', ring.address);

        // more complex
        bancorNetwork = await BancorNetwork.new(contractRegistry.address, {from: accounts[0]});
        bancorNetworkId = await contractIds.BANCOR_NETWORK.call();
        await contractRegistry.registerAddress(bancorNetworkId, bancorNetwork.address);

        bancorConverter = await BancorConverter.new(ring.address, contractRegistry.address, 0, etherToken.address, weight10Percent, {from: accounts[0]});
        console.log('bancorConverter address: ', bancorConverter.address);

        bancorExchange = await BancorExchange.new(ring.address, bancorNetwork.address, bancorConverter.address, {from: accounts[0]})
        console.log('bancorExchange address: ', bancorExchange.address);


        //do this to make SmartToken.totalSupply > 0
        await ring.issue(accounts[0], 110000 * 10**18, {from:accounts[0]});
        await ring.setOwner(bancorConverter.address, {from:accounts[0]});

        await etherToken.deposit({from: accounts[0], value: 10**18});
        await etherToken.transfer(bancorConverter.address, 10**18, {from: accounts[0]});

        await whiteList.addAddress(bancorExchange.address, {from: accounts[0]});
        await bancorConverter.setConversionWhitelist(whiteList.address, {from: accounts[0]});

        await bancorNetwork.registerEtherToken(etherToken.address, true, {from : accounts[0]});

        await bancorExchange.setQuickBuyPath([etherToken.address, etherToken.address, ring.address], {from: accounts[0]})
        await bancorExchange.setQuickSellPath([ring.address, ring.address, etherToken.address], {from: accounts[0]});
        console.log('bancorExchange address: ', bancorExchange.address);
    })

    it('verify configuration in contractRegistry', async() => {
        // check registry
        let contractFeaturesInRegistry = await contractRegistry.addressOf(await contractIds.CONTRACT_FEATURES.call());
        assert.equal(contractFeaturesInRegistry, contractFeatures.address);

        let bancorGasPriceLimitInRegistry = await contractRegistry.addressOf(await contractIds.BANCOR_GAS_PRICE_LIMIT.call());
        assert.equal(bancorGasPriceLimitInRegistry, bancorGasPriceLimit.address);

        let bancorFormulaInRegistry = await contractRegistry.addressOf(await contractIds.BANCOR_FORMULA.call());
        assert.equal(bancorFormulaInRegistry, bancorFormula.address);

        let bancorNetworkInRegistry = await contractRegistry.addressOf(await contractIds.BANCOR_NETWORK.call());
        assert.equal(bancorNetworkInRegistry, bancorNetwork.address);

    })

    it('bancorConverter related checks', async () => {

        assert.equal(await bancorConverter.token(), ring.address);
        // smartToken's owner
        assert.equal(await ring.owner(), bancorConverter.address);
        // whitelist
        assert.equal(await bancorConverter.conversionWhitelist(), whiteList.address);
        // registry
        let registryInConverter = await bancorConverter.registry();
        assert.equal(registryInConverter, contractRegistry.address);
        // check connector balance
        assert.equal(await etherToken.balanceOf(bancorConverter.address), 10**18);
        let connecorBalance = await bancorConverter.getConnectorBalance(etherToken.address);
        assert(connecorBalance.valueOf() > 0);
        let supply = await ring.totalSupply();
        assert(supply.valueOf() > 0);

        let featureWhitelist = await bancorConverter.CONVERTER_CONVERSION_WHITELIST.call();
        let isSupported = await contractFeatures.isSupported.call(bancorConverter.address, featureWhitelist);
        assert(isSupported);

        let maxConversionFee = await bancorConverter.maxConversionFee.call();
        assert.equal(maxConversionFee, 0);
        let conversionsEnabled = await bancorConverter.conversionsEnabled.call();
        assert.equal(conversionsEnabled, true);

        let connector = await bancorConverter.connectors(etherToken.address);
        verifyConnector(connector, true, true, 100000, false, 0);

        let amount = await bancorConverter.getPurchaseReturn(etherToken.address, 10**18);
        console.log('buy amount: ', amount.valueOf());

        let amount1 = await bancorConverter.getReturn(etherToken.address, ring.address, 10**18);
        console.log('getReturn: ', amount1.valueOf());
        assert.equal(amount.valueOf(), amount1.valueOf());
    })

    it('bancorNetwork related checks', async () => {
        assert(await contractFeatures.isSupported(bancorConverter.address, await featureIds.CONVERTER_CONVERSION_WHITELIST.call()));
        assert(await whiteList.isWhitelisted(bancorExchange.address));
        assert(await bancorNetwork.etherTokens(etherToken.address));
        let registryInNetwork = await bancorNetwork.registry();
        assert.equal(registryInNetwork, contractRegistry.address);
        // connctor number
        let count = await bancorConverter.connectorTokenCount();
        assert.equal(count, 1);
        // get return by path
        // let amount = await bancorNetwork.getReturnByPath([etherToken.address, etherToken.address, ring.address], 10**18);
        // console.log('get return by path: ', amount.valueOf());

    })

    it('bancorExchange related checks', async () => {
        let et = await bancorExchange.quickBuyPath(0);
        assert.equal(et, etherToken.address);
        assert.equal(et, await bancorExchange.quickBuyPath(1));
        assert.equal(ring.address, await bancorExchange.quickBuyPath(2));

        let st = await bancorExchange.quickSellPath(0);
        assert.equal(st, ring.address);
        assert.equal(st, await bancorExchange.quickSellPath(1));
        assert.equal(etherToken.address, await bancorExchange.quickSellPath(2));

    })

    it('buy rings', async() => {
       let amount = await bancorExchange.buyRING(1, {from: accounts[1], value: 10**18});
       assert(amount.valueOf() > 1);
    })

})

// contract('ClockAuction deployment', async(accounts) => {
//
//
//     it('deploy series contracts', async () => {
//         registry = await SettingsRegistry.new({from: accounts[0]});
//         console.log('registry address: ', registry.address);
//
//         auctionSettingsId = AuctionSettingIds.new({from: accounts[0]})
//         console.log('auctionSettingIds address: ', auctionSettingsId.address)
//
//         atlantis = await Atlantis.new({from: accounts[0]});
//         console.log('atlantis address: ', atlantis.address)
//
//         landGenesisData = await LandGenesisData.new({from: accounts[0]});
//         console.log('landGenesisData address: ', landGenesisData.address);
//
//
//         bancorExchange = await BancorExchange.new('')
//     })
//
//
//
// })

