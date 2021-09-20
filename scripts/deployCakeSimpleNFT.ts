import hardhat from "hardhat";

async function main() {
    console.log("deploy start")

    const CakeSimpleNFTV1 = await hardhat.ethers.getContractFactory("CakeSimpleNFTV1")
    const cakeSimpleNFTV1 = await CakeSimpleNFTV1.deploy()
    console.log(`CakeSimpleNFTV1 address: ${cakeSimpleNFTV1.address}`)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
