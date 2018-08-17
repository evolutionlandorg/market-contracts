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
    constructor(
        address _nftAddress,
        address _RING,
        address _tokenVendor,
        uint256 _cut,
        uint256 _waitingMinutes,
        uint _claimBounty,
        address _landData,
        address _kton
        )
    public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        // InterfaceId_ERC721 = 0x80ac58cd;
        require(candidateContract.supportsInterface(0x80ac58cd));
        nonFungibleContract = candidateContract;
        _setRING(_RING);
        _setTokenVendor(_tokenVendor);
        _setBidWaitingTime(_waitingMinutes);
        _setClaimBounty(_claimBounty);
        _setLandData(_landData);
        _setKTON(_kton);
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


    // TODO: in genesis auction, if tokenId is reserverd,
    // you need to buy it with kr.
    function _buyWithKTON(address _from, uint256 _tokenId, uint256 _valueInKTON) internal returns (uint256){
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        // require this is the first bid of auction
        require(auction.lastBidder == 0x0, "It's not the first bid, KTON is not allowed");

        require(_isOnAuction(auction));
        // computingg priceInKTON is the same as computing priceInRING
        // but there is no bounty for claiming
        uint priceInKTON = _currentPriceInRING(auction,0);

        require(_valueInKTON >= priceInKTON,
            "your offer is lower than the current price, try again with a higher one.");

        uint bidMoment = _buyProcess(_from, auction, priceInKTON, address(KTON));

        // Tell the world!
        emit NewBid(_tokenId, _from, priceInKTON, 3, bidMoment);

        return priceInKTON;
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
    }


    /// @dev bid with eth(in wei). Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bidWithETH(uint256 _tokenId, uint256 _bidAmount, address _buyer)
    internal
    returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // TODO: if it is genesis auction ,require that tokenId is not reserved
        if (auction.lastBidder == 0x0) {
            require(!landData.isReserved(_tokenId));
        }

        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction));

        // Check that the incoming bid is higher than the current
        // price
        uint256 priceInETH = _currentPriceETH(auction);
        // assure msg.value larger than current price in ring
        require(_bidAmount >= priceInETH,
            "your offer is lower than the current price, try again with a higher one.");

        // assure that this get ring back from tokenVendor
        require(tokenVendor.buyToken.value(_bidAmount)(address(this)));

        // if no one has bidden for auction, priceInRING is computed through linear operation
        // if someone has already bidden for it before, priceInRING is last bidder's offer
        uint priceInRING = _currentPriceInRING(auction, claimBounty);

        uint bidMoment = _buyProcess(_buyer, auction, priceInRING.sub(claimBounty), address(RING));

        // Tell the world!
        emit NewBid(_tokenId, _buyer, priceInRING, 1, bidMoment);

        return priceInRING;
    }



    // here to handle bid for LAND(NFT) using RING
    // @dev bidder must use RING.transfer(address(this), _valueInRING, bytes32(_tokenId)
    // to invoke this function
    // @param _data - need to be generated from bytes32(tokenId)
    function tokenFallback(address _from, uint256 _valueInToken, bytes _data) public whenNotPaused {
        uint256 tokenId = bytesToUint256(_data);
        if (msg.sender == address(RING)) {
            // assure it can be converted into uint256 correctly
            require(_data.length == 32);
            // TODO: add restriction
            require(!landData.isReserved(tokenId));
            _bidWithRING(_from, tokenId, _valueInToken);
        }

        if (msg.sender == address(KTON)) {
            // assure it can be converted into uint256 correctly
            require(_data.length == 32);
            // TODO: add restriction
            // require tokenId is reserved
            require(landData.isReserved(tokenId));

            _buyWithKTON(_from, tokenId, _valueInToken);
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

        _transfer(auction.lastBidder, _tokenId);
        // if there is claimBounty, then reward who invoke this function
        if (claimBounty > 0) {
            require(RING.transfer(msg.sender, claimBounty));
        }

        emit AuctionSuccessful(_tokenId, auction.lastRecord, auction.lastBidder);
    }

    // @dev bid with RING. Computes the price and transfers winnings.
    function _bidWithRING(address _from, uint256 _tokenId, uint256 _valueInRING) internal returns (uint256){
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];

        // TODO: if it is genesis auction ,require that tokenId is not reserved
        if (auction.lastBidder == 0x0) {
            require(!landData.isReserved(_tokenId));
        }

        require(_isOnAuction(auction));

        // Check that the incoming bid is higher than the current price
        uint priceInRING = _currentPriceInRING(auction, claimBounty);
        require(_valueInRING >= priceInRING,
            "your offer is lower than the current price, try again with a higher one.");

        uint bidMoment = _buyProcess(_from, auction, priceInRING.sub(claimBounty),address(RING));

        // Tell the world!
        emit NewBid(_tokenId, _from, priceInRING, 2, bidMoment);

        return priceInRING;
    }

    // TODO: add _token to compatible backwards with ring and eth
    function _buyProcess(address _buyer, Auction storage _auction, uint _priceInToken, address _token)
    internal
    canBeStoredWith128Bits(_priceInToken)
    returns (uint256){

        // last bidder's info
        address lastBidder;
        // last bidder's price
        uint lastRecord;


    if (_auction.lastBidder != 0x0) {
            // TODO: repair bug of first bid's time limitation
            // if this the first bid, there is no time limitation
            require(now <= _auction.lastBidStartAt + bidWaitingTime);
            lastBidder = _auction.lastBidder;
            lastRecord = uint256(_auction.lastRecord);
        }

        // modify bid-related member variables
        uint bidMoment = now;
        _auction.lastBidder = _buyer;
        _auction.lastRecord = uint128(_priceInToken);
        _auction.lastBidStartAt = bidMoment;

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address seller = _auction.seller;

        // the first bid
        if (lastBidder == 0x0 && _priceInToken > 0) {
            //  Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            //  value <= price, so this subtraction can't go negative.)
            uint256 sellerProceedsInRING = _priceInToken - _computeCut(_priceInToken);
            // transfer to the seller
            RING.transfer(seller, sellerProceedsInRING);
        }

        // TODO: the math calculation needs further check
        //  not the first bid
        if (lastRecord > 0 && lastBidder != 0x0) {
            // _priceInRING that is larger than lastRecord
            // was assured in _currentPriceInRING(_auction)
            // here double check
            uint extraForEach = (_priceInToken.sub(lastRecord)) / 2;
            uint realReturn = extraForEach.sub(_computeCut(extraForEach));
            ERC20(_token).transfer(seller, realReturn);
            ERC20(_token).transfer(lastBidder, (realReturn + lastRecord));
        }

        return bidMoment;
    }


    //@ param _waitingMinutes - waiting time (in minutes)
    function setBidWaitingTime(uint _waitingMinutes) public onlyOwner {
        _setBidWaitingTime(_waitingMinutes);
    }

    function setClaimBounty(uint _claimBounty) public onlyOwner {
        _setClaimBounty(_claimBounty);
    }

    function setLandData(address _landData) public onlyOwner {
        _setLandData(_landData);
    }

    function setKTON(address _kton) public onlyOwner {
        _setKTON(_kton);
    }

    function bytesToUint256(bytes b) public pure returns (uint256) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return uint256(out);
    }


}
