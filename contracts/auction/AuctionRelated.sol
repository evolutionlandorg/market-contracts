pragma solidity ^0.4.23;

import "./ClockAuctionBase.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/// @title Clock auction for non-fungible tokens.
contract AuctionRelated is Pausable, ClockAuctionBase {


    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    //  NOTE: change _startingPrice and _endingPrice in from wei to ring for user-friendly reason
    /// @param _startingPriceInRING - Price of item (in ring) at beginning of auction.
    /// @param _endingPriceInRING - Price of item (in ring) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    /// @param _seller - Seller, if not the message sender
    function _createAuction(
        address _from,
        uint256 _tokenId,
        uint256 _startingPriceInRING,
        uint256 _endingPriceInRING,
        uint256 _duration,
        address _seller
    )
    internal
    whenNotPaused
    canBeStoredWith128Bits(_startingPriceInRING)
    canBeStoredWith128Bits(_endingPriceInRING)
    canBeStoredWith64Bits(_duration)
    {
        require(_owns(_from, _tokenId), "you are not the owner, dont do this.");
        _escrow(_from, _tokenId);

        Auction memory auction = Auction(
            _seller,
            uint128(_startingPriceInRING),
            uint128(_endingPriceInRING),
            uint64(_duration),
            uint64(now),
            // which refer to lastRecord, lastBidder, lastBidStartAt
            // all set to zero when initialized
            0,0x0,0
        );
        _addAuction(_tokenId, auction);
    }



    /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
    public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        // once someone has bidden for this auction, no one has the right to cancel it.
        require(auction.lastBidder == 0x0);
        _cancelAuction(_tokenId, seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
    whenPaused
    onlyOwner
    public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        // once someone has bidden for this auction, no one has the right to cancel it.
        require(auction.lastBidder == 0x0);
        _cancelAuction(_tokenId, auction.seller);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
    public
    view
    returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt,
        uint128 lastRecord,
        address lastBidder,
        uint256 lastBidStartAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
        auction.seller,
        auction.startingPriceInRING,
        auction.endingPriceInRING,
        auction.duration,
        auction.startedAt,
        auction.lastRecord,
        auction.lastBidder,
        auction.lastBidStartAt
        );
    }

    /// @dev Returns the current price of an auction.
    /// 
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPriceInRING(uint256 _tokenId)
    public
    view
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPriceInRING(auction);
    }

    // to apply for the safeTransferFrom
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    )
    public
    returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }


    function setTokenVendor(address _tokenVendor) public onlyOwner {
        _setTokenVendor(_tokenVendor);
    }

    function setRING(address _ring) public onlyOwner {
        _setRING(_ring);
    }

    //@dev only NFT contract can invoke this
    //@param _from - owner of _tokenId
    function receiveApproval(
        address _from,
        uint256 _tokenId,
        bytes _extraData)
    public
    whenNotPaused
    {
        require(msg.sender == address(nonFungibleContract));

        uint256 startingPriceInRING;
        uint256 endingPriceInRING;
        uint256 duration;
        address seller;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            startingPriceInRING := mload(add(ptr,132))
            endingPriceInRING := mload(add(ptr,164))
            duration := mload(add(ptr,196))
            seller := mload(add(ptr,228))
        }

        _createAuction(_from, _tokenId, startingPriceInRING, endingPriceInRING, duration, seller);
    }

    // get auction's price of last bidder offered
    // @dev return price of _auction (in RING)
    function getLastRecord(uint _tokenId) public returns (uint256) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        return auction.lastRecord;
    }

    function getLastBidder(uint _tokenId) public view returns (address) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        return auction.lastBidder;
    }

    function getLastBidStartAt(uint _tokenId) public view returns (uint256) {
        // Get a reference to the auction struct
        Auction storage auction = tokenIdToAuction[_tokenId];
        return auction.lastBidStartAt;
    }


}
