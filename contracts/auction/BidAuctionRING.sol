pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import "./ClockAuctionBase.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/// @title Clock auction for non-fungible tokens.
contract BidAuctionRING is Pausable, ClockAuctionBase {

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000. It can be considered as transaction fee.
    // TODO: add RING address
    constructor(address _nftAddress, address _RING, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        // InterfaceId_ERC721 = 0x80ac58cd;
        require(candidateContract.supportsInterface(0x80ac58cd));
        nonFungibleContract = candidateContract;
        RING = ERC20(_RING);
    }

    // TODO: modified the withdraw function
    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token != 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }


    // here to handle bid for LAND(NFT) using RING
    // @dev bidder must use RING.transfer(address(this), _valueInRING, bytes32(_tokenId) to invoke this function
    // @param _data - need to be generated from bytes32(tokenId)
    function tokenFallback(address _from, uint256 _valueInRING, bytes _data) public whenNotPaused {
        if (msg.sender == address(RING)) {
            // assure it can be converted into uint256 correctly
            require(_data.length == 32);
            uint256 tokenId = bytesToUint256(_data);
            require(tokenId != 0);
            _bidWithRING(_from, tokenId, _valueInRING);
            _transfer(_from, tokenId);
        }

    }




    // @dev bid with RING. Computes the price and transfers winnings.
    function _bidWithRING(address _from, uint256 _tokenId, uint256 _valueInRING) internal returns (uint256){
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        // current price in RING
        uint priceInRING = _currentPriceInRING(auction);
        require (_valueInRING >= priceInRING);
        _removeAuction(_tokenId);

        if (priceInRING > 0) {
            uint256 auctioneerCutInRING = _computeCut(priceInRING);
            uint256 sellerProceedsInRING = priceInRING - auctioneerCutInRING;
            RING.transfer(seller, sellerProceedsInRING);
            emit AuctionSuccessful(_tokenId, priceInRING, _from);
        }

        return priceInRING;
    }

    // TODO: set RING and only Owner can do this
    function setRING(address _ring) public onlyOwner {
        _setRING(_ring);
    }


    function bytesToUint256(bytes b) public pure returns (uint256) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return uint256(out);
    }




}
