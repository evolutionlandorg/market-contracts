pragma solidity ^0.4.23;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract TokenVendor is Ownable{
    using SafeMath for uint256;

    ERC20 public token;

    uint256 public buyTokenRate;   // 1 ETH = 30000 RING.

    uint256 public sellTokenRate;   // sellTokenRate = buyTokenRate * 11 /10

    uint256 public totalBuyTokenTransfered;

    uint256 public totalBuyEtherCollected;

    uint256 public totalSellEthTransfered;

    uint256 public totalSellTokenCollected;

    constructor(address _token) public {
        token = ERC20(_token);

        buyTokenRate = 30000;
        sellTokenRate = 33000;
    }

    /// @notice If anybody sends Ether directly to this contract, consider he is
    ///  getting tokens.
    function () public payable {
        buyToken(msg.sender);

    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public{
        require(msg.sender == address(token));

        sellToken(_from, _value);
    }

    function buyToken(address _th) public payable returns (bool) {
        require(_th != 0x0);
        require(msg.value > 0);

        uint256 _toFund = msg.value;

        uint256 tokensGenerating = _toFund.mul(buyTokenRate);

        if (tokensGenerating > token.balanceOf(this)) {
            tokensGenerating = token.balanceOf(this);
            _toFund = token.balanceOf(this).div(buyTokenRate);
        }

        require(token.transfer(_th, tokensGenerating));

        // DONE: Add statistics:
        totalBuyTokenTransfered = totalBuyTokenTransfered.add(tokensGenerating);

        // DONE: Add statistics:
        totalBuyEtherCollected = totalBuyEtherCollected.add(_toFund);

        emit NewBuy(_th, _toFund, tokensGenerating);

        uint256 toReturn = msg.value.sub(_toFund);
        if (toReturn > 0) {
            _th.transfer(toReturn);
        }

        return true;
    }

    function sellToken(address _th, uint256 _value) public returns (bool) {
        require(_th != 0x0);
        require(_value > 0);

        uint256 _toFund = _value;

        uint256 ethGenerating = _toFund.div(sellTokenRate);

        if (ethGenerating > address(this).balance) {
            ethGenerating = address(this).balance;
            _toFund = address(this).balance.mul(sellTokenRate);
        }

        _th.transfer(ethGenerating);

        // DONE: Statistics.
        totalSellEthTransfered = totalSellEthTransfered.add(ethGenerating);

        totalSellTokenCollected = totalSellTokenCollected.add(_toFund);

        emit NewSell(_th, _value, ethGenerating);

        uint256 toReturn = _value.sub(_toFund);

        if (toReturn > 0) {
            require(token.transfer(_th, toReturn));
        }

        return true;
    }

    // Recommended OP: buyTokenRate will be changed once a day.
    // There is a limit of price change, that is, no more than +/- 10 percentage compared to the day before.
    // If the token in yesterday consuming to fast, then token price should go higher
    // Otherwise, token price should go lower, sell pricate should be changed accordingly
    function changeBuyTokenRate(uint256 _newBuyTokenRate) public onlyOwner {
        require(_newBuyTokenRate > 0);

        emit BuyRateChanged(buyTokenRate, _newBuyTokenRate);
        buyTokenRate = _newBuyTokenRate;
    }

    function changeSellTokenRate(uint256 _newSellTokenRate) public onlyOwner {
        require(_newSellTokenRate > 0);

        emit SellRateChanged(sellTokenRate, _newSellTokenRate);
        sellTokenRate = _newSellTokenRate;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 claimToken = ERC20(_token);
        uint balance = claimToken.balanceOf(this);
        claimToken.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }


    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event BuyRateChanged(uint256 previousBuyRate, uint256 newBuyRate);
    event SellRateChanged(uint256 previousSellRate, uint256 newSellRate);
    event NewBuy(address indexed _th, uint256 _amount, uint256 _tokens);
    event NewSell(address indexed _th, uint256 _amount, uint256 _weis);
}