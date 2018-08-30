pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract LuckyBag is Pausable {
    using SafeMath for *;

    uint256 public goldBagAmountForSale;
    uint256 public silverBagAmountForSale;

    uint256 public goldBagPrice;    // amount of eth for each gold bag.
    uint256 public silverBagPrice;

    address public wallet;

    constructor(address _wallet, uint256 _goldBagAmountForSale, uint256 _silverBagAmountForSale) public
    {
        require(_wallet != address(0), "need a good wallet to store fund");
        require(_goldBagAmountForSale > 0, "Gold bag amount need to be no-zero");
        require(_silverBagAmountForSale > 0, "Silver bag amount need to be no-zero");

        wallet = _wallet;
        goldBagAmountForSale = _goldBagAmountForSale;
        silverBagAmountForSale = _silverBagAmountForSale;
    }

    function buyBags(address _buyer, uint256 _goldBagAmount, uint256 _silverBagAmount) payable public whenNotPaused {
        require(_buyer != address(0));
        uint256 charge = _goldBagAmount.mul(goldBagPrice).add(_silverBagAmount.mul(silverBagPrice));
        require(msg.value >= charge, "No enough ether for buying lucky bags.");
        require(_goldBagAmount > 0 || _silverBagAmount > 0);

        if (_goldBagAmount > 0)
        {
            goldBagAmountForSale = goldBagAmountForSale.sub(_goldBagAmount);
            emit GoldBagSale(_buyer, _goldBagAmount, goldBagPrice);
        }

        if (_silverBagAmount > 0)
        {
            silverBagAmountForSale = silverBagAmountForSale.sub(_silverBagAmount);
            emit SilverBagSale(_buyer, _silverBagAmount, silverBagPrice);
        }

        wallet.transfer(charge);

        if (msg.value > charge)
        {
            uint256 weiToRefund = msg.value.sub(charge);
            _buyer.transfer(weiToRefund);
            emit EthRefunded(_buyer, weiToRefund);
        }
    }

    function buyBags(uint256 _goldBagAmount, uint256 _silverBagAmount) payable public whenNotPaused {
        buyBags(msg.sender, _goldBagAmount, _silverBagAmount);
    }

    function updateGoldBagAmountAndPrice(uint256 _goldBagAmountForSale, uint256 _goldBagPrice) public onlyOwner {
        goldBagAmountForSale = _goldBagAmountForSale;
        goldBagPrice = _goldBagPrice;
    }

    function updateSilverBagAmountAndPrice(uint256 _silverBagAmountForSale, uint256 _silverBagPrice) public onlyOwner {
        silverBagAmountForSale = _silverBagAmountForSale;
        silverBagPrice = _silverBagPrice;
    }


//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyOwner public {
      if (_token == 0x0) {
          owner.transfer(address(this).balance);
          return;
      }

      ERC20 token = ERC20(_token);
      uint balance = token.balanceOf(this);
      token.transfer(owner, balance);

      emit ClaimedTokens(_token, owner, balance);
    }


    event GoldBagSale(address indexed _user, uint256 _amount, uint256 _price);
    
    event SilverBagSale(address indexed _user, uint256 _amount, uint256 _price);

    event EthRefunded(address indexed buyer, uint256 value);

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);

}
