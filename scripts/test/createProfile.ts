import hre, { ethers } from "hardhat";

export async function createProfile() {

    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const account = (await ethers.getSigners())[0];
    const deployerAddress = await account.getAddress();
    const blocksToWait = hre.network.name === "localhost" ? 0 : 5;

    const balance = await ethers.provider.getBalance(deployerAddress);

    const registry = "0x4AAcca72145e1dF2aeC137E1f3C5E3D75DB8b5f3";

    console.table({
        contract: "registry: create profile",
        chainId: chainId,
        network: networkName,
        deployerAddress: deployerAddress,
        registry: registry,
        balance: ethers.formatEther(balance)
    });

    console.log("Creating profile...");
    const instance = await ethers.getContractAt('Registry', registry);

    await instance.createProfile(
        1, // none
        "Direct Allocation", // name
        {
            protocol: 1,
            pointer: "bafybeia4khbew3r2mkflyn7nzlvfzcb3qpfeftz5ivpzfwn77ollj47gqi"
        }, // metadata
        "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C", // owner
        ["0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C"] // members
    );

    console.log("profile created at:", instance.target);
  
    return instance.target;
}

createProfile().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/createProfile.ts --network sepolia