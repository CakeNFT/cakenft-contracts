import { expect } from "chai";
import { ecsign } from "ethereumjs-util";
import { BigNumber, constants } from "ethers";
import { waffle } from "hardhat";
import CakeNFTArtifact from "../artifacts/contracts/CakeNFT.sol/CakeNFT.json";
import CakeNFTStoreArtifact from "../artifacts/contracts/CakeNFTStore.sol/CakeNFTStore.json";
import MockCakeArtifact from "../artifacts/contracts/MockCake.sol/MockCake.json";
import { CakeNFT, CakeNFTStore, MockCake } from "../typechain";
import { mine } from "./shared/utils/blockchain";
import { expandTo18Decimals } from "./shared/utils/number";
import { getERC20ApprovalDigest, getERC721ApprovalDigest } from "./shared/utils/standard";

const { deployContract } = waffle;

describe("CakeNFTStore", () => {
    let cake: MockCake;
    let nft: CakeNFT;
    let market: CakeNFTStore;

    const provider = waffle.provider;
    const [admin, other] = provider.getWallets();

    beforeEach(async () => {
        cake = await deployContract(
            admin,
            MockCakeArtifact,
            []
        ) as MockCake;
        nft = await deployContract(
            admin,
            CakeNFTArtifact,
            ["Test NFT", "TEST", "1", "http://testnft.com"]
        ) as CakeNFT;
        market = await deployContract(
            admin,
            CakeNFTStoreArtifact,
            [cake.address]
        ) as CakeNFTStore;
    })

    context("new CakeNFTStore", async () => {
        it("sell and buy", async () => {
            await nft.mint()
            await nft.approve(market.address, 0)
            const price = expandTo18Decimals(10)
            await expect(market.sell(nft.address, 0, price))
                .to.emit(market, "Sell")
                .withArgs(nft.address, 0, admin.address, price)
            await cake.connect(other).mint(price);
            await cake.connect(other).approve(market.address, price);
            await expect(market.connect(other).buy(nft.address, 0))
                .to.emit(market, "Buy")
                .withArgs(nft.address, 0, other.address, price)
        })

        it("sell with permit and buy", async () => {
            await nft.mint()
            await nft.approve(market.address, 0)

            const nonce = await nft.nonces(admin.address)
            const deadline = constants.MaxUint256
            const digest = await getERC721ApprovalDigest(
                nft,
                { spender: market.address, id: BigNumber.from(0) },
                nonce,
                deadline
            )

            const { v, r, s } = ecsign(Buffer.from(digest.slice(2), "hex"), Buffer.from(admin.privateKey.slice(2), "hex"))

            const price = expandTo18Decimals(10)
            await expect(market.sellWithPermit(nft.address, 0, price, deadline, v, r, s))
                .to.emit(market, "Sell")
                .withArgs(nft.address, 0, admin.address, price)
            await cake.connect(other).mint(price);
            await cake.connect(other).approve(market.address, price);
            await expect(market.connect(other).buy(nft.address, 0))
                .to.emit(market, "Buy")
                .withArgs(nft.address, 0, other.address, price)
        })

        it("sell and cancel", async () => {
            await nft.mint()
            await nft.approve(market.address, 0)
            const price = expandTo18Decimals(10)
            await expect(market.sell(nft.address, 0, price))
                .to.emit(market, "Sell")
                .withArgs(nft.address, 0, admin.address, price)
            await expect(market.cancelSale(nft.address, 0))
                .to.emit(market, "CancelSale")
                .withArgs(nft.address, 0, admin.address)
        })

        it("offer and accpet", async () => {
            await nft.mint()
            await nft.approve(market.address, 0)
            const price = expandTo18Decimals(10)
            await cake.connect(other).mint(price);
            await cake.connect(other).approve(market.address, price);
            await expect(market.connect(other).offer(nft.address, 0, price))
                .to.emit(market, "Offer")
                .withArgs(nft.address, 0, 0, other.address, price)
            await expect(market.acceptOffer(nft.address, 0, 0))
                .to.emit(market, "AcceptOffer")
                .withArgs(nft.address, 0, 0, admin.address)
        })

        it("offer and cancel", async () => {
            await nft.mint()
            await nft.approve(market.address, 0)
            const price = expandTo18Decimals(10)
            await cake.connect(other).mint(price);
            await cake.connect(other).approve(market.address, price);
            await expect(market.connect(other).offer(nft.address, 0, price))
                .to.emit(market, "Offer")
                .withArgs(nft.address, 0, 0, other.address, price)
            await expect(market.connect(other).cancelOffer(nft.address, 0, 0))
                .to.emit(market, "CancelOffer")
                .withArgs(nft.address, 0, 0, other.address)
        })

        it("auction and bid and claim", async () => {
            await nft.mint()
            await nft.approve(market.address, 0)
            const startPrice = expandTo18Decimals(10)
            const bidPrice = expandTo18Decimals(11)
            const endBlock = (await provider.getBlockNumber()) + 100;
            await expect(market.auction(nft.address, 0, startPrice, endBlock))
                .to.emit(market, "Auction")
                .withArgs(nft.address, 0, admin.address, startPrice, endBlock)
            await cake.connect(other).mint(startPrice);
            await cake.connect(other).approve(market.address, startPrice);
            await expect(market.connect(other).bid(nft.address, 0, startPrice))
                .to.emit(market, "Bid")
                .withArgs(nft.address, 0, other.address, startPrice)
            await cake.connect(other).mint(bidPrice);
            await cake.connect(other).approve(market.address, bidPrice);
            await expect(market.connect(other).bid(nft.address, 0, bidPrice))
                .to.emit(market, "Bid")
                .withArgs(nft.address, 0, other.address, bidPrice)
            await mine(100);
            await expect(market.connect(other).claim(nft.address, 0))
                .to.emit(market, "Claim")
                .withArgs(nft.address, 0, other.address, bidPrice)
        })

        it("auction with permit and bid and claim", async () => {
            await nft.mint()

            const nonce = await nft.nonces(admin.address)
            const deadline = constants.MaxUint256
            const digest = await getERC721ApprovalDigest(
                nft,
                { spender: market.address, id: BigNumber.from(0) },
                nonce,
                deadline
            )

            const { v, r, s } = ecsign(Buffer.from(digest.slice(2), "hex"), Buffer.from(admin.privateKey.slice(2), "hex"))

            const startPrice = expandTo18Decimals(10)
            const bidPrice = expandTo18Decimals(11)
            const endBlock = (await provider.getBlockNumber()) + 100;

            await expect(market.auctionWithPermit(nft.address, 0, startPrice, endBlock, deadline, v, r, s))
                .to.emit(market, "Auction")
                .withArgs(nft.address, 0, admin.address, startPrice, endBlock)
            await cake.connect(other).mint(startPrice);
            await cake.connect(other).approve(market.address, startPrice);
            await expect(market.connect(other).bid(nft.address, 0, startPrice))
                .to.emit(market, "Bid")
                .withArgs(nft.address, 0, other.address, startPrice)
            await cake.connect(other).mint(bidPrice);
            await cake.connect(other).approve(market.address, bidPrice);
            await expect(market.connect(other).bid(nft.address, 0, bidPrice))
                .to.emit(market, "Bid")
                .withArgs(nft.address, 0, other.address, bidPrice)
            await mine(100);
            await expect(market.connect(other).claim(nft.address, 0))
                .to.emit(market, "Claim")
                .withArgs(nft.address, 0, other.address, bidPrice)
        })

        it("auction and cancel", async () => {
            await nft.mint()
            await nft.approve(market.address, 0)
            const startPrice = expandTo18Decimals(10)
            const endBlock = (await provider.getBlockNumber()) + 100;
            await expect(market.auction(nft.address, 0, startPrice, endBlock))
                .to.emit(market, "Auction")
                .withArgs(nft.address, 0, admin.address, startPrice, endBlock)
            await expect(market.cancelAuction(nft.address, 0))
                .to.emit(market, "CancelAuction")
                .withArgs(nft.address, 0, admin.address)
        })
    })
})