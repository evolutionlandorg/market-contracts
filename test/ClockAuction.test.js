const utils = require('./utils/time');
const Web3 = require('web3');
var web3 = new Web3(Web3.givenProvider);
var increaseTime = utils.increaseTime;
var increaseTimeTo = utils.increaseTimeTo;

const ClockAuctionInital = require('./initial/ClockAuctionInitial');
var initClockAuction = ClockAuctionInital.initClockAuction;

const RING = artifacts.require('StandardERC223');
const SettingsRegistry = artifacts.require('SettingsRegistry');
const ClaimBountyCalculator = artifacts.require('ClaimBountyCalculator');
const AuctionSettingIds = artifacts.require('AuctionSettingIds');
const MysteriousTreasure = artifacts.require('MysteriousTreasure');
const GenesisHolder = artifacts.require('GenesisHolder')
const LandGenesisData = artifacts.require('LandGenesisData');
const Atlantis = artifacts.require('Atlantis');
const ClockAuction = artifacts.require('ClockAuction')


const COIN = 10**18;
// 4%
const uint_auction_cut = 400;
// 30 minutes
const uint_auction_bid_waiting_time = 1800;


var genesisHolder;
var atlantis;
var clockAuction;
var ring;



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


    before('deploy series contracts', async () => {
        let initial = await initClockAuction(accounts);
        ring = initial.ring;
        clockAuction = initial.clockAuction;
        atlantis = initial.atlantis;
        genesisHolder = initial.genesisHolder;
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

        await RING.at(ring.address).contract.transfer['address,uint256,bytes'](clockAuction.address, 100000 * COIN, '0xffffffffffffffffffffffffffffff9b0000000000000000000000000000000c00000000000000000000000002A98FDb710Ea5611423cC1a62c0d6ecF88A4E2E', {from: accounts[0], gas:3000000});
        console.log('balanceof clockauction: ', await ring.balanceOf(clockAuction.address));
        let auction = await clockAuction.getAuction(tokenId);
        firstBidRecord = auction[6];
        console.log('firstBidRecord: ', firstBidRecord.valueOf());
        verifyAuctionInBid(auction, accounts[0], 100000 * COIN, 50000 * COIN, 300, ring.address, accounts[0], accounts[1]);
    })

    it('bid with eth', async () => {
        let tokenId = '0x' + (await atlantis.tokenOfOwnerByIndex(clockAuction.address, 0)).toString(16);
        console.log('tokenid in bidwitheth: ', tokenId);
        let ringBalancePrev0 = await ring.balanceOf(accounts[0]);


        await clockAuction.bidWithETH(tokenId, accounts[3], {from: accounts[2], value: 2 * COIN});
        let auction = await clockAuction.getAuction(tokenId);
        secondBidRecord = auction[6];
        console.log('secondBidRecord: ', secondBidRecord.valueOf());
        verifyAuctionInBid(auction, accounts[0], 100000 * COIN, 50000 * COIN, 300, ring.address, accounts[2], accounts[3]);
        // require (lastrecord * 1.1 = thisrecord)
        assert.equal(firstBidRecord * 1.1, secondBidRecord, 'bid amount is not required');
        let ringBalanceNow0 = await ring.balanceOf(accounts[0]);
        assert(ringBalanceNow0.toNumber() > ringBalancePrev0.toNumber());
    });

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

        // get lastBidder
        let newOwner = (await clockAuction.getAuction(tokenId))[7];
        console.log('lastBidder: ', newOwner);
        assert.equal(newOwner, accounts[2], 'new owner is now lastbidder');

        // console.log('has box in landdata: ', await landGenesisData.hasBox(tokenId));

        await clockAuction.claimLandAsset(tokenId, {from: accounts[3]});
        let owner = await atlantis.ownerOf(tokenId);
        assert.equal(owner, accounts[2]);
        console.log('owner: ', owner);
    });



})

