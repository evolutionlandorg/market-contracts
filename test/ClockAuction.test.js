/**
 * test document: https://docs.google.com/spreadsheets/d/1iqsyrUixZPlZH1u4Ocfb_uV9n2JRiXRKAuJ3BWTC5Zs/edit#gid=0
 */
const time = require('./utils/time');
const utils = require('./utils/Utils');
const Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider);
var increaseTime = time.increaseTime;

const ClockAuctionInital = require('./initial/ClockAuctionInitial');
var initClockAuction = ClockAuctionInital.initClockAuction;

const StandardERC223 = artifacts.require('StandardERC223');
const SettingsRegistry = artifacts.require('SettingsRegistry');
const ClaimBountyCalculator = artifacts.require('ClaimBountyCalculator');
const AuctionSettingIds = artifacts.require('AuctionSettingIds');
const MysteriousTreasure = artifacts.require('MysteriousTreasure');
const GenesisHolder = artifacts.require('GenesisHolder')
const LandGenesisData = artifacts.require('LandGenesisData');
const Atlantis = artifacts.require('Atlantis');
const ClockAuction = artifacts.require('ClockAuction');


const COIN = 10**18;
// 4%
const uint_auction_cut = 400;
// 30 minutes
const uint_auction_bid_waiting_time = 1800;


var genesisHolder;
var atlantis;
var clockAuction;
var ring;
var landGenesisData;
var kton;

// duration is in second
// startingPrice and endingPrice is in COIN
function generateCreateData(startingPrice, endingPrice, duration, seller) {
    let commonAuctionData = web3.utils.toTwosComplement(startingPrice) + web3.utils.padLeft(endingPrice, 64, '0').substring(2) + web3.utils.padLeft(duration, 64, '0').substring(2) + web3.utils.padLeft(seller, 64, '0').substring(2);
    return commonAuctionData;
}

function generateBidData(tokenId, referer) {
    let bidData = web3.utils.toTwosComplement(tokenId) + web3.utils.padLeft(referer, 64, '0').substring(2);
    console.log("LOGGING BID DATA: ", bidData);
    return bidData;
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


contract('ClockAuction deployment', async(accounts) => {

    let firstBidRecord;
    let secondBidRecord;

    let genesisCommonLandOne;
    let genesisCommonLandTwo;
    let genesisReserveLand;
    let commonLand;
    let notExitLand = 1;


    before('deploy series contracts', async () => {
        let initial = await initClockAuction(accounts);
        ring = initial.ring;
        clockAuction = initial.clockAuction;
        atlantis = initial.atlantis;
        genesisHolder = initial.genesisHolder;
        landGenesisData = initial.landGenesisData;
        kton = initial.kton;

        genesisCommonLandOne = await atlantis.encodeTokenId(-99, 10);
        genesisCommonLandTwo = await atlantis.encodeTokenId(-99,11);
        genesisReserveLand = await atlantis.encodeTokenId(-100, 0);
        commonLand = await atlantis.encodeTokenId(-101, 2);

        await atlantis.assignNewLand(-99, 10, genesisHolder.address);
        await atlantis.assignNewLand(-99, 11, genesisHolder.address);
        await atlantis.assignNewLand(-100, 0, genesisHolder.address);
        await atlantis.assignNewLand(-101, 2, accounts[0]);

        await landGenesisData.addLandPixel(genesisReserveLand, 1210696734349198945878116);

    })

    it('[create-dsw-01], common people create auction', async () => {
        assert.equal(await atlantis.ownerOf(commonLand), accounts[0]);
        let auctionData = await generateCreateData(100 * COIN, 10 * COIN, 60, accounts[0]);
        await atlantis.approveAndCall(clockAuction.address, commonLand, auctionData);
        assert.equal(await atlantis.ownerOf(commonLand), clockAuction.address);
        let auction = await clockAuction.getAuction(commonLand);
        verifyAuctionInitial(auction, accounts[0], 100*COIN, 10*COIN, 60, ring.address, 0, 0, 0);
    })

    it('[create-dsw-02], common people create auction which already created', async () => {
        try {
            let auctionData = await generateCreateData(100 * COIN, 10 * COIN, 60, accounts[0]);
            await atlantis.approveAndCall(clockAuction.address, commonLand, auctionData);
            assert(false, "did not throw.")
        } catch (err) {
            utils.ensureException(err);
        }
    })

    it('[create-dsw-03], common people use createAuction function', async() => {
        try {
            await clockAuction.createAuction(commonLand, 100*COIN, 10*COIN, 60, Date.now() / 1000, ring.address);
            assert(false, "did not throw.")
        } catch (err) {
            utils.ensureException(err);
        }
    })

    it('[create-dsw-04], genesisHolder create auction when land does not exist', async() => {
        try {
            await genesisHolder.createAuction(notExitLand, 100*COIN, 10*COIN, 60, Date.now() / 1000, ring.address);
            assert(false, "did not throw.")
        } catch (err) {
            utils.ensureException(err);
        }
    })

    it('[create-dsw-05], genesisHolder create auction', async () => {
        assert.equal(await atlantis.ownerOf(genesisCommonLandOne), genesisHolder.address, 'this land does not belong to genesisHolder');
        await genesisHolder.createAuction(genesisCommonLandOne, 100*COIN, 10*COIN, 60, Date.now() / 1000, ring.address, {from: accounts[1]});
        assert.equal(await atlantis.ownerOf(genesisCommonLandOne), clockAuction.address, 'auction creation failed.');
        let auction = await clockAuction.getAuction(genesisCommonLandOne);
        verifyAuctionInitial(auction, genesisHolder.address, 100*COIN, 10*COIN, 60, ring.address, 0, 0, 0);
    })

    it('[create-dsw-06], genesisHolder create auction which already created', async() => {
        try {
            await genesisHolder.createAuction(genesisCommonLandOne, 100*COIN, 10*COIN, 60, Date.now() / 1000, ring.address, {from: accounts[1]});
            assert(false, "did not throw.")
        } catch (err) {
            utils.ensureException(err);
        }
    })

    it('[create-dsw-07], genesisHolder create auction while msg.sender is not operator', async() => {
        try {
            await genesisHolder.createAuction(genesisCommonLandTwo, 100*COIN, 10*COIN, 60, Date.now() / 1000, ring.address, {from: accounts[0]});
            assert(false, "did not throw.")
        } catch (err) {
            utils.ensureException(err);
        }
    })

    it('[create-dsw-08], genesisHolder create auction which land is reserved but token is set to ring', async () => {
        try {
            await genesisHolder.createAuction(genesisReserveLand, 100*COIN, 10*COIN, 60, Date.now() / 1000, ring.address, {from: accounts[1]});
            assert(false, "did not throw.")
        } catch (err) {
            utils.ensureException(err);
        }
    })

    it('[create-dsw-09], genesisHolder create auction and set auction.token to kton', async () => {
        await genesisHolder.createAuction(genesisReserveLand, 100*COIN, 10*COIN, 60, Date.now() / 1000, kton.address, {from: accounts[1]});
        let auction = await clockAuction.getAuction(genesisReserveLand);
        verifyAuctionInitial(auction, genesisHolder.address, 100*COIN, 10*COIN, 60, kton.address, 0, 0, 0);
    })

    it('[preparation for bid], create an auction which start time is in far future', async() => {
        await genesisHolder.createAuction(genesisCommonLandTwo, 100*COIN, 10*COIN, 60, Date.now() / 1000 + 60, ring.address, {from: accounts[1]});
        let auction = await clockAuction.getAuction(genesisCommonLandTwo);
        verifyAuctionInitial(auction, genesisHolder.address, 100*COIN, 10*COIN, 60, ring.address, 0, 0, 0);
    })

    it('[bid-dsw-01], bid for an auction which is not started', async() => {

            // assert((await ring.balanceOf(accounts[0])).valueOf() > 0, 'accounts[0] has no rings');
            // console.log("current price: ", (await clockAuction.getCurrentPriceInToken('0xffffffffffffffffffffffffffffff9b00000000000000000000000000000002')).valueOf());
            // let bidData = await generateBidData(commonLand, accounts[2]);
            // await StandardERC223.at(ring.address).contract.transfer['address,uint256,bytes'](clockAuction.address, 100 * COIN, '0xffffffffffffffffffffffffffffff9b0000000000000000000000000000000200000000000000000000000002A98FDb710Ea5611423cC1a62c0d6ecF88A4E2E');
            // assert(false, "did not throw.")
            //
            // let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(clockAuction.address, 0)).toString(16);
            // console.log('tokenId in auction: ', tokenId);
            // assert((await ring.balanceOf(accounts[0])).valueOf() > 100000 * COIN);

            await StandardERC223.at(ring.address).contract.transfer['address,uint256,bytes'](clockAuction.address, 100 * COIN, '0xffffffffffffffffffffffffffffff9b0000000000000000000000000000000200000000000000000000000002A98FDb710Ea5611423cC1a62c0d6ecF88A4E2E', {from: accounts[0], gas:3000000});
            console.log('balanceof clockauction: ', await ring.balanceOf(clockAuction.address));
            let auction = await clockAuction.getAuction('0xffffffffffffffffffffffffffffff9b00000000000000000000000000000002');
            firstBidRecord = auction[6];
            console.log('firstBidRecord: ', firstBidRecord);
           // verifyAuctionInBid(auction, accounts[0], 100000 * COIN, 50000 * COIN, 300, ring.address, accounts[0], accounts[1]);


    })



    // it('create an auction', async() => {
    //     let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(accounts[0], 0)).toString(16);
    //     await atlantis.approveAndCall(clockAuction.address, tokenId,
    //         '0x00000000000000000000000000000000000000000000152d02c7e14af6800000000000000000000000000000000000000000000000000a968163f0a57b400000000000000000000000000000000000000000000000000000000000000000012c00000000000000000000000089f590313Aa830C5bda128c76d49ddE89C9C831a');
    //     // token's owner change to clockAuction
    //     let owner = await atlantis.ownerOf(tokenId);
    //     assert.equal(owner, clockAuction.address);
    //
    //     let auction1 = await clockAuction.getAuction(tokenId);
    //     verifyAuctionInitial(auction1, accounts[0], 100000 * COIN, 50000 * COIN, 300, ring.address, 0, 0, 0);
    // })
    //
    // it('bid for auction', async() => {
    //     let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(clockAuction.address, 0)).toString(16);
    //     console.log('tokenId in auction: ', tokenId);
    //     assert((await ring.balanceOf(accounts[0])).valueOf() > 100000 * COIN);
    //
    //     await RING.at(ring.address).contract.transfer['address,uint256,bytes'](clockAuction.address, 100000 * COIN, '0xffffffffffffffffffffffffffffff9b0000000000000000000000000000000c00000000000000000000000002A98FDb710Ea5611423cC1a62c0d6ecF88A4E2E', {from: accounts[0], gas:3000000});
    //     console.log('balanceof clockauction: ', await ring.balanceOf(clockAuction.address));
    //     let auction = await clockAuction.getAuction(tokenId);
    //     firstBidRecord = auction[6];
    //     console.log('firstBidRecord: ', firstBidRecord.valueOf());
    //     verifyAuctionInBid(auction, accounts[0], 100000 * COIN, 50000 * COIN, 300, ring.address, accounts[0], accounts[1]);
    // })
    //
    // it('bid with eth', async () => {
    //     let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(clockAuction.address, 0)).toString(16);
    //     console.log('tokenid in bidwitheth: ', tokenId);
    //     let ringBalancePrev0 = await ring.balanceOf(accounts[0]);
    //
    //
    //     await clockAuction.bidWithETH(tokenId, accounts[3], {from: accounts[2], value: 2 * COIN});
    //     let auction = await clockAuction.getAuction(tokenId);
    //     secondBidRecord = auction[6];
    //     console.log('secondBidRecord: ', secondBidRecord.valueOf());
    //     verifyAuctionInBid(auction, accounts[0], 100000 * COIN, 50000 * COIN, 300, ring.address, accounts[2], accounts[3]);
    //     // require (lastrecord * 1.1 = thisrecord)
    //     assert.equal(firstBidRecord * 1.1, secondBidRecord, 'bid amount is not required');
    //     let ringBalanceNow0 = await ring.balanceOf(accounts[0]);
    //     assert(ringBalanceNow0.toNumber() > ringBalancePrev0.toNumber());
    // });
    //
    // it('claim land asset', async () => {
    //     let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(clockAuction.address, 0)).toString(16);
    //     assert.equal(await atlantis.ownerOf(tokenId), clockAuction.address);
    //     console.log('token owner confirmed!')
    //     let expireTime = ((await clockAuction.getAuction(tokenId))[8]).toNumber() + uint_auction_bid_waiting_time;
    //     console.log('expire time: ', expireTime);
    //     let  now = (await web3.eth.getBlock("latest")).timestamp;
    //     console.log('now: ', now);
    //     await increaseTime(uint_auction_bid_waiting_time);
    //     let increasedTime = (await web3.eth.getBlock("latest")).timestamp;
    //     console.log('time after increasion: ', increasedTime);
    //     assert((increasedTime - expireTime) >= 0, 'time increasion failed!')
    //
    //     // get lastBidder
    //     let newOwner = (await clockAuction.getAuction(tokenId))[7];
    //     console.log('lastBidder: ', newOwner);
    //     assert.equal(newOwner, accounts[2], 'new owner is now lastbidder');
    //
    //     // console.log('has box in landdata: ', await landGenesisData.hasBox(tokenId));
    //
    //     await clockAuction.claimLandAsset(tokenId, {from: accounts[3]});
    //     let owner = await atlantis.ownerOf(tokenId);
    //     assert.equal(owner, accounts[2]);
    //     console.log('owner: ', owner);
    // });



})

