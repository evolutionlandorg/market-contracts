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

module.exports = {
    initBancor: initBancor
}


async function initBancor(accounts) {
    let contractRegistry = await ContractRegistry.new();
    console.log('contractRegistry address: ', contractRegistry.address);

    let contractIds = await ContractIds.new();

    let contractFeatures = await ContractFeatures.new();
    let contractFeaturesId = await contractIds.CONTRACT_FEATURES.call();
    await contractRegistry.registerAddress(contractFeaturesId, contractFeatures.address);
    console.log('contractFeatures address: ', contractFeatures.address);

    let bancorFormula = await BancorFormula.new();
    let formulaId = await contractIds.BANCOR_FORMULA.call();
    await contractRegistry.registerAddress(formulaId, bancorFormula.address);
    console.log('bancorFormula address: ', bancorFormula.address);

    let bancorGasPriceLimit = await BancorGasPriceLimit.new(gasPrice);
    let gasPriceLimitId = await contractIds.BANCOR_GAS_PRICE_LIMIT.call();
    await contractRegistry.registerAddress(gasPriceLimitId, bancorGasPriceLimit.address);
    console.log('bancorGasPriceLimit address: ', bancorGasPriceLimit.address);

    let featureIds = await FeatureIds.new();
    console.log('featureIds address: ', featureIds.address);

    let whiteList = await WhiteList.new();
    console.log('whiteList address: ', whiteList.address);

    let etherToken = await EtherToken.new();
    console.log('etherToken address: ', etherToken.address);

    let ring = await RING.new("RING");
    console.log('ring address: ', ring.address);

    // more complex
    let bancorNetwork = await BancorNetwork.new(contractRegistry.address);
    let bancorNetworkId = await contractIds.BANCOR_NETWORK.call();
    await contractRegistry.registerAddress(bancorNetworkId, bancorNetwork.address);

    let bancorConverter = await BancorConverter.new(ring.address, contractRegistry.address, 0, etherToken.address, weight10Percent);
    console.log('bancorConverter address: ', bancorConverter.address);

    let bancorExchange = await BancorExchange.new(ring.address, bancorNetwork.address, bancorConverter.address);
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

    return {ring: ring, bancorExchange: bancorExchange};

}
