import hre, { ethers } from "hardhat";
import { registryConfig } from "../config/registry.config";
import { confirmContinue, prettyNum } from "../utils/script-utils";

export async function createProfile() {

    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const account = (await ethers.getSigners())[0];
    const deployerAddress = await account.getAddress();
    const blocksToWait = hre.network.name === "localhost" ? 0 : 5;

    const balance = await ethers.provider.getBalance(deployerAddress);

    const registry = registryConfig[chainId].registry;

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

    await instance.createProfile({
        nonce: 1,
        name: "test",
        metadata: {
            protocol: 1,
            pointer: "bafybeia4khbew3r2mkflyn7nzlvfzcb3qpfeftz5ivpzfwn77ollj47gqi"
        },
        owner: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
        members: []
    });

    console.log("profile created at:", instance.target);
  
    return instance.target;
}

// createProfile().catch((error) => {
//     console.error(error);
//     process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/createProfile.ts --network sepolia