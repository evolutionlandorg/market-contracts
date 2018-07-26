pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol";
import "./ClockAuctionBase.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

/// @title Clock auction for non-fungible tokens.
contract ClockAuction is Pausable, ClockAuctionBase {

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each auction, must be
    ///  between 0-10,000.
    // TODO: add tokenVendor addess
    // TODO: add RING address
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

    /// @dev Creates and begins a new auction.
    /// @param _tokenId - ID of token to auction, sender must be owner.
    // TODO: change _startingPrice and _endingPrice in from wei to ring for user-friendly reason
    /// @param _startingPriceInRING - Price of item (in ring) at beginning of auction.
    /// @param _endingPriceInRING - Price of item (in ring) at end of auction.
    /// @param _duration - Length of time to move between starting
    ///  price and ending price (in seconds).
    /// @param _seller - Seller, if not the message sender
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPriceInRING,
        uint256 _endingPriceInRING,
        uint256 _duration,
        address _seller
    )
        public
        whenNotPaused
        canBeStoredWith128Bits(_startingPriceInRING)
        canBeStoredWith128Bits(_endingPriceInRING)
        canBeStoredWith64Bits(_duration)
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);

        uint256 exchangeRate = getExchangeRate();
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPriceInRING / exchangeRate),
            uint128(_endingPriceInRING / exchangeRate),
            uint128(_startingPriceInRING),
            uint128(_endingPriceInRING),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
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
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    // TODO: set tokenVendor and only Owner can do this
    function setTokenVendor(address _tokenVendor) public onlyOwner {
        _setTokenVendor(_tokenVendor);
    }

    // TODO: set RING and only Owner can do this
    function setRING(address _ring) public onlyOwner {
        _setRING(_ring);
    }

    // TODO: add tokenFallback(address _from, uint256 _value, bytes _data)
    // 👆here to handle bid for LAND(NFT) using RING
    // @dev bidder must use transfer(address(this), _valueInRING, bytes32(_tokenId) to invoke this function
    // @param _data - need to be generated from bytes32(tokenId)
    function tokenFallback(address _from, uint256 _valueInRING, bytes _data) public whenNotPaused {
        if (msg.sender == address(RING)) {
            // assure it can be converted into uint256 correctly
            require(_data.length == 32);
            uint256 tokenId = bytesToUint256(_data);
            require(tokenId != 0);
            _bidWithRING(tokenId, _valueInRING);
            _transfer(_from, tokenId);
        }
    }


    function bytesToUint256(bytes b) public pure returns (uint256) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return uint256(out);
    }




}
