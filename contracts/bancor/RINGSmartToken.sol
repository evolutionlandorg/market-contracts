pragma solidity ^0.4.24;

import "bancor-contracts/solidity/contracts/token/interfaces/ISmartToken.sol";
import "bancor-contracts/solidity/contracts/token/interfaces/IERC20Token.sol";
import 'bancor-contracts/solidity/contracts//utility/Utils.sol';
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./interfaces/IUnIssuedTokenHolder.sol";

contract RINGSmartToken is ISmartToken, Ownable, Utils {
    IERC20Token public ring;

    // RING's token controller need to set and read this property for controller ring's transfer too.
    // Need to be setted in gloabl registry for both token and smart token usage.
    bool public transfersEnabled = true;

    // TODO: if the ring burn tokens, the tokenSupply cannot get reflected.
    uint256 public totalSupply = 0;

    // TODO: unissuedTokenHolder need to approve this.
    IUnIssuedTokenHolder public unissuedTokenHolder;

    // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewSmartToken(address _token);
    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);

    constructor(address _ring, address _unissuedTokenHolder) public {
        ring = IERC20Token(_ring);
        unissuedTokenHolder = IUnIssuedTokenHolder(_unissuedTokenHolder);
    }

    // allows execution only when transfers aren't disabled
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

    function disableTransfers(bool _disable) public onlyOwner {
        transfersEnabled = !_disable;
    }

    // For some pre-genesis-balances (e.g. those balance not issued from bancor or unissudedTokenHolder), need to leave this method
    // for update token supply and reveal the real balances.
    function updateTokenSupplyToSyncRINGToken(uint256 _newTokenSupply) public onlyOwner {
        require(_newTokenSupply <= ring.totalSupply());

        totalSupply = _newTokenSupply;
    }

    function issueTokensToDecreaseCW(address _to, uint256 _amount) public onlyOwner {
        issueInternal(_to, _amount);
    }

    function destroyTokensToIncreaseCW(address _from, uint256 _amount) public onlyOwner {
        destroyInternal(_from, _amount);
    }

    // TODO: Only Bancor Convertor
    function issue(address _to, uint256 _amount) internal {
        issueInternal(_to, _amount);
    }

    // TODO: Only Bancor Convertor
    function destroy(address _from, uint256 _amount) internal {
        destroyInternal(_from, _amount);
    }

    function issueInternal(address _to, uint256 _amount) internal {
        totalSupply = safeAdd(totalSupply, _amount);

        unissuedTokenHolder.issue(_to, _amount);

        require(totalSupply <= ring.totalSupply());

        emit Issuance(_amount);
    }

    // TODO: Only Bancor Convertor
    function destroyInternal(address _from, uint256 _amount) internal {
        unissuedTokenHolder.destroy(_from, _amount);
        
        totalSupply = safeSub(totalSupply, _amount);

        emit Destruction(_amount);
    }

    function name() public view returns (string) {
        return ring.name();
    }

    function symbol() public view returns (string) {
        return ring.symbol();
    }

    function decimals() public view returns (uint8) {
        return ring.decimals();
    }
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return ring.balanceOf(_owner);
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return ring.allowance(_owner, _spender);
    }

    // msg.sender will change here, so directly use transferFrom instead.
    function transfer(address _to, uint256 _value) public returns (bool success){
        return ring.transferFrom(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        return ring.transferFrom(_from, _to, _value);
    }

    // msg.sender will change here, so do not support, use ring.approve instead.
    function approve(address _spender, uint256 _value) public returns (bool success){
        revert();
    }

}