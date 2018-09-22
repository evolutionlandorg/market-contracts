
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

const gasPrice = 22000000000;
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



contract('bancor deployment', async(accounts) => {
    let contractFeaturesId;
    let gasPriceLimitId;
    let formulaId;
    let bancorNetworkId;

    before('deploy and configure', async() => {
        contractRegistry = await ContractRegistry.new({from: accounts[0]});
        contractIds = await ContractIds.new({from: accounts[0]});
        console.log('contractRegistry address: ', contractRegistry.address);

        contractFeatures = await ContractFeatures.new({from: accounts[0]});
        contractFeaturesId = await contractIds.CONTRACT_FEATURES.call();
        await contractRegistry.registerAddress(contractFeaturesId, contractFeatures.address);
        console.log('contractFeatures address: ', contractFeatures.address);

        bancorFormula = await BancorFormula.new({from: accounts[0]});
        formulaId = await contractIds.BANCOR_FORMULA.call();
        await contractRegistry.registerAddress(formulaId, bancorFormula.address);
        console.log('bancorFormula address: ', bancorFormula);

        bancorGasPriceLimit = await BancorGasPriceLimit.new(gasPrice, {from: accounts[0]});
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
        await bancorConverter.setConversionWhitelist(whiteList.address, {from: accounts[0]})
        await bancorNetwork.registerEtherToken(etherToken.address, true, {from : accounts[0]});
        await bancorExchange.setQuickBuyPath([etherToken.address, etherToken.address, ring.address], {from: accounts[0]})
        await bancorExchange.setQuickSellPath([ring.address, ring.address, etherToken.address], {from: accounts[0]});
        console.log(bancorExchange.address)
    })

    it('verify deployment', async() => {
        // check registry


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

