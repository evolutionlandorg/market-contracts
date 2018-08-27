pragma solidity ^0.4.24;

import "bancor-contracts/solidity/contracts/token/interfaces/IERC20Token.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./interfaces/IUnIssuedTokenHolder.sol";

contract UnIssuedTokenHolder {
    address public originToken;
    address public smartToken;

    constructor(address _originToken, address _smartToken) public {
        originToken = _originToken;
        smartToken = _smartToken;
    }

    modifier smartTokenOnly {
        assert(msg.sender == smartToken);
        _;
    }

    function originToken() public view returns (address)
    {
        return originToken;
    }

    function smartToken() public returns (address) {
        return smartToken;
    }

    function issue(address _to, uint256 _amount) public smartTokenOnly {
        require(IERC20Token(originToken).transfer(_to, _amount));
    }

    function destroy(address _from, uint256 _amount) public smartTokenOnly {
        require(IERC20Token(originToken).transferFrom(_from, this, _amount));
    }
}