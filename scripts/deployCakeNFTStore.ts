import hardhat from "hardhat";

async function main() {
    console.log("deploy start")

    const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82";
    const CAKE_MASTER_CHEF = "0x73feaa1eE314F8c655E354234017bE2193C9E24E";

    const CakeOwnerVault = await hardhat.ethers.getContractFactory("CakeOwnerVault")
    const cakeOwnerVault = await CakeOwnerVault.deploy(CAKE, CAKE_MASTER_CHEF)
    console.log(`CakeOwnerVault address: ${cakeOwnerVault.address}`)

    const CakeVault = await hardhat.ethers.getContractFactory("CakeVault")
    const cakeVault = await CakeVault.deploy(CAKE, CAKE_MASTER_CHEF)
    console.log(`CakeVault address: ${cakeVault.address}`)

    const CakeNFTStore = await hardhat.ethers.getContractFactory("CakeNFTStore")
    const cakeNFTStore = await CakeNFTStore.deploy(
        CAKE, CAKE_MASTER_CHEF,
        cakeOwnerVault.address, cakeVault.address,
        "0xE671E2511E02de8Ad99Cde43adf0C48ED883DabD"
    )
    console.log(`CakeNFTStore address: ${cakeNFTStore.address}`)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
