pragma solidity ^0.4.23;

import "./AuctionRelated.sol";

contract ClockAuction is AuctionRelated {

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000. It can be considered as transaction fee.
    constructor(address _nftAddress, address _RING, address _tokenVendor, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        // InterfaceId_ERC721 = 0x80ac58cd;
        require(candidateContract.supportsInterface(0x80ac58cd));
        nonFungibleContract = candidateContract;
        RING = ERC20(_RING);
        tokenVendor = TokenVendor(_tokenVendor);
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


    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bidWithETH(uint256 _tokenId)
    public
    payable
    whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
        _bidWithETH(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }


    /// @dev bid with eth(in wei). Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bidWithETH(uint256 _tokenId, uint256 _bidAmount)
    internal
    returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));

        // Check that the incoming bid is higher than the current
        // price
        uint256 priceInETH = _currentPriceETH(auction);
        // assure msg.value larger than current price in ring
        require(_bidAmount >= priceInETH);

        uint priceInRING = _currentPriceInRING(auction);

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can't have a reentrancy attack.
        _removeAuction(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (priceInRING > 0) {
            // assure that this get ring back from tokenVendor
            require(tokenVendor.buyToken.value(_bidAmount)(address(this)));
            //  Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            //  value <= price, so this subtraction can't go negative.)
            uint256 auctioneerCutInRING = _computeCut(priceInRING);
            //  eth that should be given back to the seller
            uint256 sellerProceedsInRING = priceInRING - auctioneerCutInRING;

            // transfer to the seller
            RING.transfer(seller, sellerProceedsInRING);
        }

        // Tell the world!
        emit AuctionSuccessful(_tokenId, priceInRING, msg.sender);

        return priceInRING;
    }


    // here to handle bid for LAND(NFT) using RING
    // @dev bidder must use RING.transfer(address(this), _valueInRING, bytes32(_tokenId) to invoke this function
    // @param _data - need to be generated from bytes32(tokenId)
    function tokenFallback(address _from, uint256 _valueInRING, bytes _data) public whenNotPaused {
        if (msg.sender == address(RING)) {
            // assure it can be converted into uint256 correctly
            require(_data.length == 32);
            uint256 tokenId = bytesToUint256(_data);

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


    function bytesToUint256(bytes b) public pure returns (uint256) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return uint256(out);
    }



}
