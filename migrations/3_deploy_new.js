const SettingsRegistry = artifacts.require('SettingsRegistry');
const AuctionSettingIds = artifacts.require('AuctionSettingIds');
const GenesisHolder = artifacts.require('GenesisHolder')
const LandBase = artifacts.require('LandBase');
const ObjectOwnership = artifacts.require('ObjectOwnership');
const ClockAuction = artifacts.require('ClockAuction')
const Proxy = artifacts.require('OwnedUpgradeabilityProxy');
const LandBaseAuthority = artifacts.require('LandBaseAuthority');
const RevenuePool = artifacts.require('RevenuePool');
const UserPoints = artifacts.require('UserPoints');
const UserPointsAuthority = artifacts.require('UserPointsAuthority');
const PointsRewardPool = artifacts.require('PointsRewardPool');

var conf = {
    registry_address: '0xf21930682df28044d88623e0707facf419477041',
    from: '0x4cc4c344eba849dc09ac9af4bff1977e44fc1d7e',
    kton_address: '0x8db914ef206c7f6c36e5223fce17900b587f46d2',
}

let revenuePoolProxy_address;
let pointsRewardPoolProxy_address;
let userPointsProxy_address;

module.exports = function (deployer, network) {
    if(network != 'kovan') {
        return;
    }

    deployer.deploy(AuctionSettingIds);
    deployer.deploy(Proxy).then(async () => {
        let revenueProxy = await Proxy.deployed();
        revenuePoolProxy_address = revenueProxy.address;
        console.log("revenuePool Proxy address: ", revenuePoolProxy_address);
        await deployer.deploy(RevenuePool);
        await deployer.deploy(Proxy)
    }).then(async() => {
        let pointsRewardPoolProxy = await Proxy.deployed();
        pointsRewardPoolProxy_address = pointsRewardPoolProxy.address;
        console.log("pointsRewardPool Proxy address: ", pointsRewardPoolProxy_address);
        await deployer.deploy(PointsRewardPool);
        await deployer.deploy(Proxy);
    }).then(async() => {
        let userPointsProxy = await Proxy.deployed();
        userPointsProxy_address = userPointsProxy.address;
        console.log("userPoints Proxy address: ", userPointsProxy_address);
        await deployer.deploy(UserPoints);
    }).then(async() => {
        await deployer.deploy(UserPointsAuthority, [revenuePoolProxy_address, pointsRewardPoolProxy_address]);
    }).then(async () => {
        // register to regisry
        let registry = await SettingsRegistry.at(conf.registry_address);
        let settingIds = await AuctionSettingIds.deployed();

        let revenueId = await settingIds.CONTRACT_REVENUE_POOL.call();
        await registry.setAddressProperty(revenueId, revenuePoolProxy_address);

        let pointsRewardId = await settingIds.CONTRACT_POINTS_REWARD_POOL.call();
        await registry.setAddressProperty(pointsRewardId, pointsRewardPoolProxy_address);

        let userPointsId = await settingIds.CONTRACT_USER_POINTS.call();
        await registry.setAddressProperty(userPointsId, userPointsProxy_address);

        let contributionId = await settingIds.CONTRACT_CONTRIBUTION_INCENTIVE_POOL.call();
        await registry.setAddressProperty(contributionId, conf.from);

        let dividendsId = await settingIds.CONTRACT_DIVIDENDS_POOL.call();
        await registry.setAddressProperty(dividendsId, conf.from);

        let devId = await settingIds.CONTRACT_DEV_POOL.call();
        await registry.setAddressProperty(devId, conf.from);

        let ktonId = await settingIds.CONTRACT_KTON_ERC20_TOKEN.call();
        await registry.setAddressProperty(ktonId, conf.kton_address);
        console.log("REGISTER DONE!")

        // upgrade
        await Proxy.at(revenuePoolProxy_address).upgradeTo(RevenuePool.address);
        await Proxy.at(pointsRewardPoolProxy_address).upgradeTo(PointsRewardPool.address);
        await Proxy.at(userPointsProxy_address).upgradeTo(UserPoints.address);
        console.log("UPGRRADE DONE!")

        // initialize
        let revenuePoolProxy = await RevenuePool.at(revenuePoolProxy_address);
        await revenuePoolProxy.initializeContract(conf.registry_address);

        let pointsRewardPoolProxy = await PointsRewardPool.at(pointsRewardPoolProxy_address);
        await pointsRewardPoolProxy.initializeContract(conf.registry_address);

        let userPointsProxy = await UserPoints.at(userPointsProxy_address);
        userPointsProxy.initializeContract();
        console.log("INITIALIZATION DONE!")
        // set Authority
        await userPointsProxy.setAuthority(UserPointsAuthority.address);

        console.log('SUCCESS! ')
    })


}