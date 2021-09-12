import hardhat from "hardhat";

async function main() {
    console.log("deploy start")

    const CakeNFTStore = await hardhat.ethers.getContractFactory("CakeNFTStore")
    const cakeNFTStore = await CakeNFTStore.deploy()
    console.log(`CakeNFTStore address: ${cakeNFTStore.address}`)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
