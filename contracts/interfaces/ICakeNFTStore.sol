// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ICakeDividend.sol";
import "./ICakeNFT.sol";
import "./ICakeStaker.sol";
import "./IUserMintNFT.sol";

interface ICakeNFTStore is ICakeDividend {
    
    event Sell(IERC721 indexed nft, uint256 indexed nftId, address indexed owner, uint256 price);
    event Buy(IERC721 indexed nft, uint256 indexed nftId, address indexed buyer, uint256 price);
    event CancelSale(IERC721 indexed nft, uint256 indexed nftId, address indexed owner);
    event UserMint(IERC721 indexed nft, uint256 indexed nftId, address indexed minter, uint256 mintPrice);
    
    event Offer(IERC721 indexed nft, uint256 indexed nftId, uint256 indexed offerId, address offeror, uint256 price);
    event CancelOffer(IERC721 indexed nft, uint256 indexed nftId, uint256 indexed offerId, address offeror);
    event AcceptOffer(IERC721 indexed nft, uint256 indexed nftId, uint256 indexed offerId, address acceptor);

    event Auction(IERC721 indexed nft, uint256 indexed nftId, address indexed owner, uint256 startPrice, uint256 endBlock);
    event CancelAuction(IERC721 indexed nft, uint256 indexed nftId, address indexed owner);
    event Bid(IERC721 indexed nft, uint256 indexed nftId, address indexed bidder, uint256 price);
    event Claim(IERC721 indexed nft, uint256 indexed nftId, address indexed bidder, uint256 price);
    
    function nfts(uint256 index) external returns (address);
    function nftCount() view external returns (uint256);
    function totalTradingVolumes(IERC721 nft) view external returns (uint256);

    function set(ICakeNFT nft, uint256 staking, uint256 fee) external;

    function sales(IERC721 nft, uint256 nftId) external returns (
        address seller,
        uint256 price
    );

    function offers(IERC721 nft, uint256 nftId, uint256 index) external returns (
        address offeror,
        uint256 price
    );
    function offerCount(IERC721 nft, uint256 nftId) view external returns (uint256);

    function auctions(IERC721 nft, uint256 nftId) external returns (
        address seller,
        uint256 startPrice,
        uint256 endBlock
    );

    function biddings(IERC721 nft, uint256 nftId, uint256 index) external returns (
        address bidder,
        uint256 price
    );
    function biddingCount(IERC721 nft, uint256 nftId) view external returns (uint256);

    function sell(IERC721 nft, uint256 nftId, uint256 price) external;
    function sellWithPermit(ICakeNFT nft, uint256 nftId, uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function checkSelling(IERC721 nft, uint256 nftId) external returns (bool);
    function buy(IERC721 nft, uint256 nftId) external;
    function cancelSale(IERC721 nft, uint256 nftId) external;

    function userMint(IUserMintNFT nft) external returns (uint256 id);

    function offer(IERC721 nft, uint256 nftId, uint256 price) external returns (uint256 offerId);
    function cancelOffer(IERC721 nft, uint256 nftId, uint256 offerId) external;
    function acceptOffer(IERC721 nft, uint256 nftId, uint256 offerId) external;

    function auction(IERC721 nft, uint256 nftId, uint256 startPrice, uint256 endBlock) external;
    function auctionWithPermit(ICakeNFT nft, uint256 nftId, uint256 startPrice, uint256 endBlock,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function cancelAuction(IERC721 nft, uint256 nftId) external;
    function checkAuction(IERC721 nft, uint256 nftId) external returns (bool);
    function bid(IERC721 nft, uint256 nftId, uint256 price) external returns (uint256 biddingId);
    function claim(IERC721 nft, uint256 nftId) external;
}
