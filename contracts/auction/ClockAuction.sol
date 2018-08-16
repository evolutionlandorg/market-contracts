pragma solidity ^0.4.23;

import "./AuctionRelated.sol";

contract ClockAuction is AuctionRelated {

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000. It can be considered as transaction fee.
    /// @param _waitingMinutes - biggest waiting time from a bid's starting to ending(in minutes)
    //TODO: add _waitingMinutes
    constructor(address _nftAddress, address _RING, address _tokenVendor, uint256 _cut, uint256 _waitingMinutes) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        // InterfaceId_ERC721 = 0x80ac58cd;
        require(candidateContract.supportsInterface(0x80ac58cd));
        nonFungibleContract = candidateContract;
        RING = ERC20(_RING);
        tokenVendor = TokenVendor(_tokenVendor);
        _setBidWaitingTime(_waitingMinutes);
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
        _bidWithETH(_tokenId, msg.value, msg.sender);
        _transfer(msg.sender, _tokenId);
    }


    /// @dev bid with eth(in wei). Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bidWithETH(uint256 _tokenId, uint256 _bidAmount, address _buyer)
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

        require(now <= auction.lastBidStartAt + bidWaitingTime);

        // Check that the incoming bid is higher than the current
        // price
        uint256 priceInETH = _currentPriceETH(auction);
        // assure msg.value larger than current price in ring
        require(_bidAmount >= priceInETH,
            "your offer is lower than the current price, try again with a higher one.");

        // if no one has bidden for auction, priceInRING is computed through linear operation
        // if someone has already bidden for it before, priceInRING is last bidder's offer
        uint priceInRING = _currentPriceInRING(auction);
        require(priceInRING < 340282366920938463463374607431768211455);

        // TODO: record last bidder's info
        // last bidder's info
        address lastBidder;
        // last bidder's price
        uint lastRecord;

        if (lastBidder != 0x0) {
            lastBidder = auction.lastBidder;
            lastRecord = uint256(auction.lastRecord);
        }

        // TODO: modify bid-related member variables
        // modify bid-related member variables
        uint bidMoment = now;
        auction.lastBidder = _buyer;
        auction.lastRecord = uint128(priceInRING);
        auction.lastBidStartAt = bidMoment;

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = auction.seller;


        // assure that this get ring back from tokenVendor
        require(tokenVendor.buyToken.value(_bidAmount)(address(this)));

        // the first bid
        if (lastBidder == 0x0 && priceInRING > 0) {
            //  Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            //  value <= price, so this subtraction can't go negative.)
            uint256 sellerProceedsInRING = priceInRING - _computeCut(priceInRING);
            // transfer to the seller
            RING.transfer(seller, sellerProceedsInRING);
        }

        //  not the first bid
        if (lastRecord > 0 && lastBidder != 0x0) {
            uint extraForEach = (priceInRING - lastRecord) / 2;
            uint realReturn = extraForEach - _computeCut(extraForEach);
            RING.transfer(seller,realReturn);
            RING.transfer(lastBidder,(realReturn + lastRecord));
        }

        // Tell the world!
        emit NewBid(_tokenId, _buyer, priceInRING, bidMoment);

        return priceInRING;
    }


    // here to handle bid for LAND(NFT) using RING
    // @dev bidder must use RING.transfer(address(this), _valueInRING, bytes32(_tokenId)
    // to invoke this function
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

    // TODO: advice: offer some reward for the person who claimed
    // @dev claim _tokenId for auction's lastBidder
    function claimLandAsset(uint _tokenId) public {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

       require(_isOnAuction(auction));
        // at least bidWaitingTime after last bidder's bid moment,
        // and no one else has bidden during this bidWaitingTime,
        // then any one can claim this token(land) for lastBidder.
        require(now >= auction.lastBidStartAt + bidWaitingTime,
        "this auction has not finished yet, try again later");
        //prevent re-entry attack
        _removeAuction(_tokenId);

        nonFungibleContract.safeTransferFrom(this, auction.lastBidder, _tokenId);

        emit AuctionSuccessful(_tokenId, auction.lastRecord, auction.lastBidder);
    }

    // @dev bid with RING. Computes the price and transfers winnings.
    function _bidWithRING(address _from, uint256 _tokenId, uint256 _valueInRING) internal returns (uint256){
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));

        require(now <= auction.lastBidStartAt + bidWaitingTime);

        // Check that the incoming bid is higher than the current price
        uint priceInRING = _currentPriceInRING(auction);
        require (_valueInRING >= priceInRING,
            "your offer is lower than the current price, try again with a higher one.");

        // TODO: record last bidder's info
        // last bidder's info
        address lastBidder;
        // last bidder's price
        uint lastRecord;

        if (lastBidder != 0x0) {
            lastBidder = auction.lastBidder;
            lastRecord = uint256(auction.lastRecord);
        }

        // TODO: modify bid-related member variables
        // modify bid-related member variables
        uint bidMoment = now;
        auction.lastBidder = _from;
        auction.lastRecord = uint128(priceInRING);
        auction.lastBidStartAt = bidMoment;

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = auction.seller;

        if (lastBidder == 0x0 && priceInRING > 0) {
            //  Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            //  value <= price, so this subtraction can't go negative.)
            uint256 sellerProceedsInRING = priceInRING - _computeCut(priceInRING);
            // transfer to the seller
            RING.transfer(seller, sellerProceedsInRING);
        }

        //  not the first bid
        if (lastRecord > 0 && lastBidder != 0x0) {
            uint extraForEach = (priceInRING - lastRecord) / 2;
            uint realReturn = extraForEach - _computeCut(extraForEach);
            RING.transfer(seller,realReturn);
            RING.transfer(lastBidder,(realReturn + lastRecord));
        }

        // Tell the world!
        emit NewBid(_tokenId, _from, priceInRING, bidMoment);

        return priceInRING;
    }


    //@ param _waitingMinutes - waiting time (in minutes)
    function setBidWaitingTime(uint _waitingMinutes) public onlyOwner {
        _setBidWaitingTime(_waitingMinutes);
    }

    function bytesToUint256(bytes b) public pure returns (uint256) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return uint256(out);
    }



}
