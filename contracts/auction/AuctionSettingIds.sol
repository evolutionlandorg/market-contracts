pragma solidity ^0.4.24;

import "@evolutionland/common/contracts/SettingIds.sol";

contract AuctionSettingIds is SettingIds {

    bytes32 public constant CONTRACT_CLOCK_AUCTION = "CONTRACT_CLOCK_AUCTION";

    // BidWaitingTime in seconds, default is 30 minutes
    // necessary period of time from invoking bid action to successfully taking the land asset.
    // if someone else bid the same auction with higher price and within bidWaitingTime, your bid failed.
    bytes32 public constant UINT_AUCTION_BID_WAITING_TIME = "UINT_AUCTION_BID_WAITING_TIME";


    bytes32 public constant CONTRACT_MYSTERIOUS_TREASURE = "CONTRACT_MYSTERIOUS_TREASURE";

    // users change eth(in wei) into ring with bancor exchange
    // which introduce bancor protocol to regulate the price of ring
    bytes32 public constant CONTRACT_BANCOR_EXCHANGE = "BANCOR_EXCHANGE";

    bytes32 public constant CONTRACT_POINTS_REWARD_POOL = "CONTRACT_POINTS_REWARD_POOL";

    // value belongs to [0, 10000000]
    bytes32 public constant UINT_EXCHANGE_ERROR_SPACE = "UINT_EXCHANGE_ERROR_SPACE";

    // "CONTRACT_CONTRIBUTION_INCENTIVE_POOL" is too long for byted32
    // so compress it to what states below
    bytes32 public constant CONTRACT_CONTRIBUTION_INCENTIVE_POOL = "CONTRACT_CONTRIBUTION_POOL";

    bytes32 public constant CONTRACT_DEV_POOL = "CONTRACT_DEV_POOL";

}
