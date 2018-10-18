pragma solidity ^0.4.24;

import "@evolutionland/common/contracts/DSAuth.sol";
import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "@evolutionland/common/contracts/SettingIds.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interfaces/ITradingRewardPool.sol";
import "./RevenuePool.sol";
import "./AuctionSettingIds.sol";

contract TradingRewardPool is DSAuth, ITradingRewardPool, AuctionSettingIds {
    using SafeMath for *;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    // tickets
    mapping (address => uint256) public tickets;

    uint256 public totalTicketAmount;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract(address _registry) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        registry = ISettingsRegistry(_registry);
    }

    function claimTicketReward() public {
        require(msg.sender == tx.origin, "Robot is not allowed.");

        address revenuePool = registry.addressOf(AuctionSettingIds.CONTRACT_REVENUE_POOL);

        RevenuePool(revenuePool)
            .settleToken(registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN));

        uint256 ticketAmount = tickets[msg.sender];

        if (ticketAmount == 0) {
            return;
        }

        uint256 seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(tx.origin)))) / (now)).add
                (block.number)
            )));

        // first part
        uint rewardAmount = (seed % (ticketAmount * 2)) * 9 / 10; 

        // second part.
        if (seed % 11 == 0) {
            rewardAmount += ticketAmount * 10;
        } else if (seed % 11 == 1) {
            rewardAmount = 0;
        }

        address ring = registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN);

        if (rewardAmount > totalTicketAmount) {
            rewardAmount = totalTicketAmount;
        }

        rewardAmount = rewardAmount * ERC20(ring).balanceOf(msg.sender) / totalTicketAmount;

        // clear ticket.
        clearTicket(msg.sender);

        ERC20(ring).transfer(msg.sender, rewardAmount);

        emit RewardClaimedWithTicket(msg.sender, ticketAmount, rewardAmount);
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public auth {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

    function addTickets(address _user, uint256 _addTicketAmount) public auth {
        tickets[_user] += _addTicketAmount;
        totalTicketAmount += _addTicketAmount;

        emit UpdatedTicketAmount(_user, tickets[_user]);
    }

    function clearTicket(address _user) public auth {
        totalTicketAmount = totalTicketAmount.sub(tickets[_user]);
        tickets[_user] = 0;
        emit UpdatedTicketAmount(_user, 0);
    }

}