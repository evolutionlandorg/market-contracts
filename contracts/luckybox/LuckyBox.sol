pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract LuckyBox is Pausable {
    using SafeMath for *;

    uint256 public goldBoxAmountForSale;
    uint256 public silverBoxAmountForSale;

    uint256 public goldBoxPrice;    // amount of eth for each gold bag.
    uint256 public silverBoxPrice;

    address public wallet;

    mapping (address => uint256) goldSalesRecord;
    mapping (address => uint256) silverSalesRecord;

    uint256 public goldSaleLimit;
    uint256 public silverSaleLimit;

    constructor(address _wallet, uint256 _goldBoxAmountForSale, uint256 _silverBoxAmountForSale) public
    {
        require(_wallet != address(0), "need a good wallet to store fund");
        require(_goldBoxAmountForSale > 0, "Gold bag amount need to be no-zero");
        require(_silverBoxAmountForSale > 0, "Silver bag amount need to be no-zero");

        wallet = _wallet;
        goldBoxAmountForSale = _goldBoxAmountForSale;
        silverBoxAmountForSale = _silverBoxAmountForSale;

        goldSaleLimit = 10;
        silverSaleLimit = 100;
    }

    function buyBoxs(address _buyer, uint256 _goldBoxAmount, uint256 _silverBoxAmount) payable public whenNotPaused {
        require(_buyer != address(0));
        require(_goldBoxAmount <= goldBoxAmountForSale && _silverBoxAmount <= silverBoxAmountForSale);
        require(goldSalesRecord[_buyer] + _goldBoxAmount <= goldSaleLimit);
        require(silverSalesRecord[_buyer] + _silverBoxAmount <= silverSaleLimit);

        uint256 charge = _goldBoxAmount.mul(goldBoxPrice).add(_silverBoxAmount.mul(silverBoxPrice));
        require(msg.value >= charge, "No enough ether for buying lucky bags.");
        require(_goldBoxAmount > 0 || _silverBoxAmount > 0);

        if (_goldBoxAmount > 0)
        {
            goldBoxAmountForSale = goldBoxAmountForSale.sub(_goldBoxAmount);
            goldSalesRecord[_buyer] += _goldBoxAmount;
            emit GoldBoxSale(_buyer, _goldBoxAmount, goldBoxPrice);
        }

        if (_silverBoxAmount > 0)
        {
            silverBoxAmountForSale = silverBoxAmountForSale.sub(_silverBoxAmount);
            silverSalesRecord[_buyer] += _silverBoxAmount;
            emit SilverBoxSale(_buyer, _silverBoxAmount, silverBoxPrice);
        }

        wallet.transfer(charge);

        if (msg.value > charge)
        {
            uint256 weiToRefund = msg.value.sub(charge);
            _buyer.transfer(weiToRefund);
            emit EthRefunded(_buyer, weiToRefund);
        }
    }

    function buyBoxs(uint256 _goldBoxAmount, uint256 _silverBoxAmount) payable public whenNotPaused {
        buyBoxs(msg.sender, _goldBoxAmount, _silverBoxAmount);
    }

    function updateGoldBoxAmountAndPrice(uint256 _goldBoxAmountForSale, uint256 _goldBoxPrice, uint256 _goldLimit) public onlyOwner {
        goldBoxAmountForSale = _goldBoxAmountForSale;
        goldBoxPrice = _goldBoxPrice;
        goldSaleLimit = _goldLimit;
    }

    function updateSilverBoxAmountAndPrice(uint256 _silverBoxAmountForSale, uint256 _silverBoxPrice, uint256 _silverLimit) public onlyOwner {
        silverBoxAmountForSale = _silverBoxAmountForSale;
        silverBoxPrice = _silverBoxPrice;
        silverSaleLimit = _silverLimit;
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


    event GoldBoxSale(address indexed _user, uint256 _amount, uint256 _price);
    
    event SilverBoxSale(address indexed _user, uint256 _amount, uint256 _price);

    event EthRefunded(address indexed buyer, uint256 value);

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);

}
