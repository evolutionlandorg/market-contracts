pragma solidity ^0.4.23;


interface ITokenVendor {


    function buyTokenRate() public returns (uint256);

    function sellTokenRate() public returns (uint256);

    function totalBuyTokenTransfered() public returns (uint256);

    function totalBuyEtherCollected() public returns (uint256);

    function totalSellEthTransfered() public returns (uint256);

    function totalSellTokenCollected() public returns (uint256);

    function tokenFallback(address _from, uint256 _value, bytes _data) public;

    function buyToken(address _th) public payable returns (bool);

    function sellToken(address _th, uint256 _value) public returns (bool);

    function changeBuyTokenRate(uint256 _newBuyTokenRate) public;

    function changeSellTokenRate(uint256 _newSellTokenRate) public;

    function claimTokens(address _token) public;

}