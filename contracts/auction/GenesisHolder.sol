pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "@evolutionland/common/contracts/interfaces/ISettingsRegistry.sol";
import "@evolutionland/common/contracts/interfaces/ILandData.sol";
import '@evolutionland/common/contracts/interfaces/IBurnableERC20.sol';
import "./interfaces/IClockAuction.sol";
import "./AuctionSettingIds.sol";


contract GenesisHolder is Ownable, AuctionSettingIds {
    ISettingsRegistry public registry;

    // the account who creates auctions
    address public operator;

    ERC20 public ring;

    // registered land-related token to this
    // do not register ring
    mapping (address => bool) registeredToken;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    constructor(ISettingsRegistry _registry, address _ring) public {
        registry = _registry;
        _setRing(_ring);
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPriceInToken,
        uint256 _endingPriceInToken,
        uint256 _duration,
        uint256 _startAt,
        address _token)
    public {

        require(msg.sender == operator);

        ILandData landData = ILandData(registry.addressOf(SettingIds.CONTRACT_LAND_DATA));
        // reserved land do not allow ring for genesis auction
        if (landData.isReserved(_tokenId)) {
            require(_token != address(ring));
        }

        IClockAuction auction = IClockAuction(registry.addressOf(AuctionSettingIds.CONTRACT_CLOCK_AUCTION));
        ERC721Basic land = ERC721Basic(registry.addressOf(SettingIds.CONTRACT_ATLANTIS_ERC721LAND));
        // aprove land to auction contract
        land.approve(address(auction), _tokenId);
        // create an auciton
        // have to set _seller to this
        auction.createAuction(_tokenId,_startingPriceInToken, _endingPriceInToken, _duration,_startAt, _token);
    }


    function cancelAuction(uint256 _tokenId) public onlyOwner {
        IClockAuction auction = IClockAuction(registry.addressOf(AuctionSettingIds.CONTRACT_CLOCK_AUCTION));
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
            IBurnableERC20(msg.sender).burn(address(this), _amount);
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

    function _setRing(address _ring) internal {
        ring = ERC20(_ring);
    }

    function setOperator(address _operator) public onlyOwner {
        operator = _operator;
    }
}
