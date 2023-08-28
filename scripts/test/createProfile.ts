import hre, { ethers } from "hardhat";
import { registryConfig } from "../config/registry.config";
import { confirmContinue, prettyNum } from "../utils/scripts";

export async function createProfile() {

    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const account = (await ethers.getSigners())[0];
    const deployerAddress = await account.getAddress();
    const blocksToWait = hre.network.name === "localhost" ? 0 : 5;

    const balance = await ethers.provider.getBalance(deployerAddress);

    const registry = registryConfig[chainId].registryProxy;

    await confirmContinue({
        contract: "registry: create profile",
        chainId: chainId,
        network: networkName,
        deployerAddress: deployerAddress,
        registry: registry,
        balance: prettyNum(balance.toString())
    });

    console.log("Creating profile...");
    const instance = await ethers.getContractAt('Registry', registry);

    await instance.createProfile(
        1, // none
        "Shitzu", // name
        {
            protocol: 1,
            pointer: "bafybeia4khbew3r2mkflyn7nzlvfzcb3qpfeftz5ivpzfwn77ollj47gqi"
        }, // metadata
        "0xB8cEF765721A6da910f14Be93e7684e9a3714123", // owner
        ["0x5cdb35fADB8262A3f88863254c870c2e6A848CcA"] // members
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