pragma solidity ^0.4.23;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ClockAuction.sol";
import "./ILandData.sol";
import './BurnableERC20.sol';


contract GenesisAuction is Ownable {

    ERC20 public ring;

    ERC721Basic public land;

    ClockAuction public auction;

    ILandData public landData;

    // registered land-related token to this
    // do not register ring
    mapping (address => bool) registeredToken;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    constructor(address _ring, address _land, address _auction, address _landData) public {
        _setRing(_ring);
        _setLand(_land);
        _setAuction(_auction);
        _setLandData(_landData);
    }


    function createAuction(
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        address _seller,
        address _token)
    public
    onlyOwner {
        // reserved land do not allow ring for genesis auction
        if (landData.isReserved(_tokenId)) {
            require(_token != address(ring));
        }

        // aprove land to auction contract
        land.approve(address(auction), _tokenId);
        // create an auciton
        // have to set _seller to this
        auction.createAuction(_tokenId,_startingPriceInToken, _endingPriceInToken, _duration, address(this), _token);
    }


    function cancelAuction(uint256 _tokenId) public onlyOwner {
        auction.cancelAuction(_tokenId);
    }

    function tokenFallback(address _from, uint _amount, bytes _data) public {
        // double check
        if (msg.sender == address(ring)) {
            return;
        }

        if (registeredToken[msg.sender] == true) {
            // burn token after receiving it
            // remember give address(this) authority to burn
            BurnableERC20(msg.sender).burn(_amount);
        }
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }


    function registerToken(address _token) public onlyOwner {
        registeredToken[_token] = true;
    }

    function unregisterToken(address _token) public onlyOwner {
        require(registeredToken[_token] == true);
        registeredToken[_token] = false;
    }

    function setRing(address _ring) public onlyOwner {
        _setRing(_ring);
    }

    function setLand(address _land) public onlyOwner {
        _setLand(_land);
    }

    function setAuction(address _auction) public onlyOwner {
        _setAuction(_auction);
    }

    function setLandData(address _landData) public onlyOwner {
        _setLandData(_landData);
    }

    function _setRing(address _ring) internal {
        ring = ERC20(_ring);
    }

    function _setLand(address _land) internal {
        land = ERC721Basic(_land);
    }

    function _setAuction(address _auction) internal {
        auction = ClockAuction(_auction);
    }

    function _setLandData(address _landData) internal {
        landData = ILandData(_landData);
    }
}
