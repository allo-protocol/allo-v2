import hre, { ethers } from "hardhat";
import { confirmContinue, prettyNum } from "./utils/script-utils";

async function main() {
    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    let account;
    let accountAddress;
    const blocksToWait = hre.network.name === "localhost" ? 0 : 10;

    account = (await ethers.getSigners())[0];
    accountAddress = await account.getAddress();
    const balance = await ethers.provider.getBalance(accountAddress);

    console.log(`This script deploys the Registry contract on ${networkName}`);

    await confirmContinue({
        contract: "Registry",
        chainId: network.chainId,
        network: network.name,
        account: accountAddress,
        balance: prettyNum(balance.toString())
    });

    console.log("Deploying Registry...");

    // TODO: Update - this is just the deployer address.
    const owner = "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42";

    const Registry = await ethers.getContractFactory("Registry");
    const instance = await Registry.deploy(owner);

    console.log("Registry deployed to:", instance.target);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployRegistry.ts --network sepolia