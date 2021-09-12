// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICakeNFTStore.sol";

contract CakeNFTStore is Ownable, ICakeNFTStore {

    IERC20 override immutable public cake;
    ICakeStaker override immutable public cakeStaker;

    constructor(IERC20 _cake, ICakeStaker _cakeStaker) {
        cake = _cake;
        cakeStaker = _cakeStaker;
    }

    uint256 public ownerFee = 25 * 1e4 / 1000;

    function setOwnerFee(uint256 fee) onlyOwner external {
        ownerFee = fee;
    }
    
    struct NFTDeployer {
        address deployer;
        uint256 staking; // 1e4
        uint256 fee; // 1e4
    }
    mapping(IERC721 => NFTDeployer) public nftDeployers;
    mapping(IERC721 => bool) public initSolds;

    function set(ICakeNFT nft, uint256 staking, uint256 fee) override external {
        require(nft.deployer() == msg.sender && staking >= 1e3 && fee <= 1e3);
        nftDeployers[nft] = NFTDeployer({
            deployer: msg.sender,
            staking: staking,
            fee: fee
        });
    }

    function setNFTDeployer(IERC721 nft, address deployer, uint256 staking, uint256 fee) onlyOwner external {
        require(staking >= 1e3 && fee <= 1e3);
        nftDeployers[nft] = NFTDeployer({
            deployer: deployer,
            staking: staking,
            fee: fee
        });
    }

    struct Sale {
        address seller;
        uint256 price;
    }
    mapping(IERC721 => mapping(uint256 => Sale)) public sales;

    struct OfferInfo {
        address offeror;
        uint256 price;
    }
    mapping(IERC721 => mapping(uint256 => OfferInfo[])) public offers;
    
    struct AuctionInfo {
        address seller;
        uint256 startPrice;
        uint256 endBlock;
    }
    mapping(IERC721 => mapping(uint256 => AuctionInfo)) public auctions;
    
    struct Bidding {
        address bidder;
        uint256 price;
    }
    mapping(IERC721 => mapping(uint256 => Bidding[])) public biddings;

    function sell(IERC721 nft, uint256 nftId, uint256 price) override public {
        require(nft.ownerOf(nftId) == msg.sender && checkAuction(nft, nftId) != true);
        nft.transferFrom(msg.sender, address(this), nftId);
        sales[nft][nftId] = Sale({
            seller: msg.sender,
            price: price
        });
        emit Sell(nft, nftId, msg.sender, price);
    }

    function sellWithPermit(ICakeNFT nft, uint256 nftId, uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) override external {
        nft.permit(address(this), nftId, deadline, v, r, s);
        sell(nft, nftId, price);
    }

    function checkSelling(IERC721 nft, uint256 nftId) override view public returns (bool) {
        return sales[nft][nftId].seller != address(0);
    }

    function distributeReward(IERC721 nft, address to, uint256 price) internal {
        uint256 _ownerFee = price * ownerFee / 1e4;
        cake.transfer(owner(), _ownerFee);

        if (initSolds[nft] != true) {
            //TODO:
            initSolds[nft] = true;
        }
        
        NFTDeployer memory deployer = nftDeployers[nft];
        if (deployer.deployer != address(0)) {
            uint256 deployerFee = price * deployer.fee / 1e4;
            cake.transfer(deployer.deployer, deployerFee);
            cake.transfer(to, price - deployerFee - _ownerFee);
        } else {
            cake.transfer(to, price - _ownerFee);
        }
    }

    function buy(IERC721 nft, uint256 nftId) override public {
        Sale memory sale = sales[nft][nftId];
        require(sale.seller != address(0));
        delete sales[nft][nftId];
        nft.transferFrom(address(this), msg.sender, nftId);
        cake.transferFrom(msg.sender, address(this), sale.price);
        distributeReward(nft, sale.seller, sale.price);
        emit Buy(nft, nftId, msg.sender, sale.price);
    }

    function cancelSale(IERC721 nft, uint256 nftId) override external {
        address seller = sales[nft][nftId].seller;
        require(seller == msg.sender);
        nft.transferFrom(address(this), seller, nftId);
        delete sales[nft][nftId];
        emit CancelSale(nft, nftId, msg.sender);
    }

    function offer(IERC721 nft, uint256 nftId, uint256 price) override public returns (uint256 offerId) {
        require(price > 0);
        OfferInfo[] storage os = offers[nft][nftId];
        offerId = os.length;
        os.push(OfferInfo({
            offeror: msg.sender,
            price: price
        }));
        cake.transferFrom(msg.sender, address(this), price);
        emit Offer(nft, nftId, offerId, msg.sender, price);
    }

    function cancelOffer(IERC721 nft, uint256 nftId, uint256 offerId) override external {
        OfferInfo[] storage os = offers[nft][nftId];
        OfferInfo memory _offer = os[offerId];
        require(_offer.offeror == msg.sender);
        uint256 price = _offer.price;
        delete os[offerId];
        cake.transfer(msg.sender, price);
        emit CancelOffer(nft, nftId, offerId, _offer.offeror);
    }

    function acceptOffer(IERC721 nft, uint256 nftId, uint256 offerId) override external {
        OfferInfo[] storage os = offers[nft][nftId];
        OfferInfo memory _offer = os[offerId];
        nft.transferFrom(msg.sender, _offer.offeror, nftId);
        uint256 price = _offer.price;
        delete os[offerId];
        distributeReward(nft, msg.sender, price);
        emit AcceptOffer(nft, nftId, offerId, msg.sender);
    }

    function auction(IERC721 nft, uint256 nftId, uint256 startPrice, uint256 endBlock) override public {
        require(nft.ownerOf(nftId) == msg.sender && checkSelling(nft, nftId) != true);
        nft.transferFrom(msg.sender, address(this), nftId);
        auctions[nft][nftId] = AuctionInfo({
            seller: msg.sender,
            startPrice: startPrice,
            endBlock: endBlock
        });
        emit Auction(nft, nftId, msg.sender, startPrice, endBlock);
    }

    function auctionWithPermit(ICakeNFT nft, uint256 nftId, uint256 startPrice, uint256 endBlock,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) override external {
        nft.permit(address(this), nftId, deadline, v, r, s);
        auction(nft, nftId, startPrice, endBlock);
    }

    function cancelAuction(IERC721 nft, uint256 nftId) override external {
        require(biddings[nft][nftId].length == 0);
        address seller = auctions[nft][nftId].seller;
        require(seller == msg.sender);
        nft.transferFrom(address(this), seller, nftId);
        delete auctions[nft][nftId];
        emit CancelAuction(nft, nftId, msg.sender);
    }

    function checkAuction(IERC721 nft, uint256 nftId) override view public returns (bool) {
        return auctions[nft][nftId].seller != address(0);
    }

    function bid(IERC721 nft, uint256 nftId, uint256 price) override public returns (uint256 biddingId) {
        AuctionInfo memory _auction = auctions[nft][nftId];
        require(_auction.seller != address(0) && block.number < _auction.endBlock);
        Bidding[] storage bs = biddings[nft][nftId];
        biddingId = bs.length;
        if (biddingId == 0) {
            require(_auction.startPrice <= price);
        } else {
            Bidding memory bestBidding = bs[biddingId - 1];
            require(bestBidding.price < price);
            cake.transfer(bestBidding.bidder, bestBidding.price);
        }
        bs.push(Bidding({
            bidder: msg.sender,
            price: price
        }));
        cake.transferFrom(msg.sender, address(this), price);
        emit Bid(nft, nftId, msg.sender, price);
    }

    function claim(IERC721 nft, uint256 nftId) override external {
        AuctionInfo memory _auction = auctions[nft][nftId];
        Bidding[] memory bs = biddings[nft][nftId];
        Bidding memory bidding = bs[bs.length - 1];
        require(bidding.bidder == msg.sender && block.number >= _auction.endBlock);
        delete auctions[nft][nftId];
        delete biddings[nft][nftId];
        nft.transferFrom(address(this), msg.sender, nftId);
        distributeReward(nft, _auction.seller, bidding.price);
        emit Claim(nft, nftId, msg.sender, bidding.price);
    }
}
