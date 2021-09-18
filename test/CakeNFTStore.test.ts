import { expect } from "chai";
import { ecsign } from "ethereumjs-util";
import { BigNumber, constants } from "ethers";
import { waffle } from "hardhat";
import CakeNFTArtifact from "../artifacts/contracts/CakeNFT.sol/CakeNFT.json";
import CakeNFTStoreArtifact from "../artifacts/contracts/CakeNFTStore.sol/CakeNFTStore.json";
import CakeOwnerVaultArtifact from "../artifacts/contracts/CakeOwnerVault.sol/CakeOwnerVault.json";
import CakeVaultArtifact from "../artifacts/contracts/CakeVault.sol/CakeVault.json";
import MockCakeArtifact from "../artifacts/contracts/MockCake.sol/MockCake.json";
import MockCakeStakerArtifact from "../artifacts/contracts/MockCakeStaker.sol/MockCakeStaker.json";
import { CakeNFT, CakeNFTStore, CakeOwnerVault, CakeVault, MockCake, MockCakeStaker } from "../typechain";
import { mine } from "./shared/utils/blockchain";
import { expandTo18Decimals } from "./shared/utils/number";
import { getERC721ApprovalDigest } from "./shared/utils/standard";

const { deployContract } = waffle;

describe("CakeNFTStore", () => {
    let cake: MockCake;
    let cakeStaker: MockCakeStaker;
    let cakeOwnerVault: CakeOwnerVault;
    let cakeVault: CakeVault;
    let nft: CakeNFT;
    let store: CakeNFTStore;

    const provider = waffle.provider;
    const [admin, other] = provider.getWallets();

    beforeEach(async () => {

        cake = await deployContract(
            admin,
            MockCakeArtifact,
            []
        ) as MockCake;

        cakeStaker = await deployContract(
            admin,
            MockCakeStakerArtifact,
            [cake.address]
        ) as MockCakeStaker;

        cakeOwnerVault = await deployContract(
            admin,
            CakeOwnerVaultArtifact,
            [cake.address, cakeStaker.address]
        ) as CakeOwnerVault;

        cakeVault = await deployContract(
            admin,
            CakeVaultArtifact,
            [cake.address, cakeStaker.address]
        ) as CakeVault;

        nft = await deployContract(
            admin,
            CakeNFTArtifact,
            ["Test NFT", "TEST", "1", "http://testnft.com"]
        ) as CakeNFT;

        store = await deployContract(
            admin,
            CakeNFTStoreArtifact,
            [cake.address, cakeStaker.address, cakeOwnerVault.address, cakeVault.address]
        ) as CakeNFTStore;
    })

    context("new CakeNFTStore", async () => {
        it("sell and buy", async () => {
            await nft.mint()
            await nft.approve(store.address, 0)
            const price = expandTo18Decimals(10)
            await expect(store.sell(nft.address, 0, price))
                .to.emit(store, "Sell")
                .withArgs(nft.address, 0, admin.address, price)
            await cake.connect(other).mint(price);
            await cake.connect(other).approve(store.address, price);
            await expect(store.connect(other).buy(nft.address, 0))
                .to.emit(store, "Buy")
                .withArgs(nft.address, 0, other.address, price)

            await expect(cakeOwnerVault.claim()).not.to.reverted;
            await expect(cakeVault.claim()).not.to.reverted;
        })

        it("sell with permit and buy", async () => {
            await nft.mint()
            await nft.approve(store.address, 0)

            const nonce = await nft.nonces(admin.address)
            const deadline = constants.MaxUint256
            const digest = await getERC721ApprovalDigest(
                nft,
                { spender: store.address, id: BigNumber.from(0) },
                nonce,
                deadline
            )

            const { v, r, s } = ecsign(Buffer.from(digest.slice(2), "hex"), Buffer.from(admin.privateKey.slice(2), "hex"))

            const price = expandTo18Decimals(10)
            await expect(store.sellWithPermit(nft.address, 0, price, deadline, v, r, s))
                .to.emit(store, "Sell")
                .withArgs(nft.address, 0, admin.address, price)
            await cake.connect(other).mint(price);
            await cake.connect(other).approve(store.address, price);
            await expect(store.connect(other).buy(nft.address, 0))
                .to.emit(store, "Buy")
                .withArgs(nft.address, 0, other.address, price)

            await expect(cakeOwnerVault.claim()).not.to.reverted;
            await expect(cakeVault.claim()).not.to.reverted;
        })

        it("sell and cancel", async () => {
            await nft.mint()
            await nft.approve(store.address, 0)
            const price = expandTo18Decimals(10)
            await expect(store.sell(nft.address, 0, price))
                .to.emit(store, "Sell")
                .withArgs(nft.address, 0, admin.address, price)
            await expect(store.cancelSale(nft.address, 0))
                .to.emit(store, "CancelSale")
                .withArgs(nft.address, 0, admin.address)

            await expect(cakeOwnerVault.claim()).not.to.reverted;
            await expect(cakeVault.claim()).not.to.reverted;
        })

        it("offer and accpet", async () => {
            await nft.mint()
            await nft.approve(store.address, 0)
            const price = expandTo18Decimals(10)
            await cake.connect(other).mint(price);
            await cake.connect(other).approve(store.address, price);
            await expect(store.connect(other).offer(nft.address, 0, price))
                .to.emit(store, "Offer")
                .withArgs(nft.address, 0, 0, other.address, price)
            await expect(store.acceptOffer(nft.address, 0, 0))
                .to.emit(store, "AcceptOffer")
                .withArgs(nft.address, 0, 0, admin.address)

            await expect(cakeOwnerVault.claim()).not.to.reverted;
            await expect(cakeVault.claim()).not.to.reverted;
        })

        it("offer and cancel", async () => {
            await nft.mint()
            await nft.approve(store.address, 0)
            const price = expandTo18Decimals(10)
            await cake.connect(other).mint(price);
            await cake.connect(other).approve(store.address, price);
            await expect(store.connect(other).offer(nft.address, 0, price))
                .to.emit(store, "Offer")
                .withArgs(nft.address, 0, 0, other.address, price)
            await expect(store.connect(other).cancelOffer(nft.address, 0, 0))
                .to.emit(store, "CancelOffer")
                .withArgs(nft.address, 0, 0, other.address)

            await expect(cakeOwnerVault.claim()).not.to.reverted;
            await expect(cakeVault.claim()).not.to.reverted;
        })

        it("auction and bid and claim", async () => {
            await nft.mint()
            await nft.approve(store.address, 0)
            const startPrice = expandTo18Decimals(10)
            const bidPrice = expandTo18Decimals(11)
            const endBlock = (await provider.getBlockNumber()) + 100;
            await expect(store.auction(nft.address, 0, startPrice, endBlock))
                .to.emit(store, "Auction")
                .withArgs(nft.address, 0, admin.address, startPrice, endBlock)
            await cake.connect(other).mint(startPrice);
            await cake.connect(other).approve(store.address, startPrice);
            await expect(store.connect(other).bid(nft.address, 0, startPrice))
                .to.emit(store, "Bid")
                .withArgs(nft.address, 0, other.address, startPrice)
            await cake.connect(other).mint(bidPrice);
            await cake.connect(other).approve(store.address, bidPrice);
            await expect(store.connect(other).bid(nft.address, 0, bidPrice))
                .to.emit(store, "Bid")
                .withArgs(nft.address, 0, other.address, bidPrice)
            await mine(100);
            await expect(store.connect(other).claim(nft.address, 0))
                .to.emit(store, "Claim")
                .withArgs(nft.address, 0, other.address, bidPrice)

            await expect(cakeOwnerVault.claim()).not.to.reverted;
            await expect(cakeVault.claim()).not.to.reverted;
        })

        it("auction with permit and bid and claim", async () => {
            await nft.mint()

            const nonce = await nft.nonces(admin.address)
            const deadline = constants.MaxUint256
            const digest = await getERC721ApprovalDigest(
                nft,
                { spender: store.address, id: BigNumber.from(0) },
                nonce,
                deadline
            )

            const { v, r, s } = ecsign(Buffer.from(digest.slice(2), "hex"), Buffer.from(admin.privateKey.slice(2), "hex"))

            const startPrice = expandTo18Decimals(10)
            const bidPrice = expandTo18Decimals(11)
            const endBlock = (await provider.getBlockNumber()) + 100;

            await expect(store.auctionWithPermit(nft.address, 0, startPrice, endBlock, deadline, v, r, s))
                .to.emit(store, "Auction")
                .withArgs(nft.address, 0, admin.address, startPrice, endBlock)
            await cake.connect(other).mint(startPrice);
            await cake.connect(other).approve(store.address, startPrice);
            await expect(store.connect(other).bid(nft.address, 0, startPrice))
                .to.emit(store, "Bid")
                .withArgs(nft.address, 0, other.address, startPrice)
            await cake.connect(other).mint(bidPrice);
            await cake.connect(other).approve(store.address, bidPrice);
            await expect(store.connect(other).bid(nft.address, 0, bidPrice))
                .to.emit(store, "Bid")
                .withArgs(nft.address, 0, other.address, bidPrice)
            await mine(100);
            await expect(store.connect(other).claim(nft.address, 0))
                .to.emit(store, "Claim")
                .withArgs(nft.address, 0, other.address, bidPrice)

            await expect(cakeOwnerVault.claim()).not.to.reverted;
            await expect(cakeVault.claim()).not.to.reverted;
        })

        it("auction and cancel", async () => {
            await nft.mint()
            await nft.approve(store.address, 0)
            const startPrice = expandTo18Decimals(10)
            const endBlock = (await provider.getBlockNumber()) + 100;
            await expect(store.auction(nft.address, 0, startPrice, endBlock))
                .to.emit(store, "Auction")
                .withArgs(nft.address, 0, admin.address, startPrice, endBlock)
            await expect(store.cancelAuction(nft.address, 0))
                .to.emit(store, "CancelAuction")
                .withArgs(nft.address, 0, admin.address)

            await expect(cakeOwnerVault.claim()).not.to.reverted;
            await expect(cakeVault.claim()).not.to.reverted;
        })

        it("buy and stake", async () => {
            await nft.mint()
            await nft.approve(store.address, 0)
            await store.set(nft.address, 5000, 1000);
            const price = expandTo18Decimals(10)
            await expect(store.sell(nft.address, 0, price))
                .to.emit(store, "Sell")
                .withArgs(nft.address, 0, admin.address, price)
            await cake.connect(other).mint(price);
            await cake.connect(other).approve(store.address, price);
            await expect(store.connect(other).buy(nft.address, 0))
                .to.emit(store, "Buy")
                .withArgs(nft.address, 0, other.address, price)

            await expect(cakeOwnerVault.claim()).not.to.reverted;
            await expect(cakeVault.claim()).not.to.reverted;
        })
    })
})