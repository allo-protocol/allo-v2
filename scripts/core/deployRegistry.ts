import hre, { ethers, upgrades } from "hardhat";
import { registryConfig } from "../config/registry.config";
import { confirmContinue, prettyNum, verifyContract } from "../utils/scripts";

export async function deployRegistry() {
    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const account = (await ethers.getSigners())[0];
    const deployerAddress = await account.getAddress();
    const blocksToWait = hre.network.name === "localhost" ? 0 : 5;

    const balance = await ethers.provider.getBalance(deployerAddress);

    console.log(`
        ////////////////////////////////////////////////////
                Deploys Registry.sol on ${networkName}
        ////////////////////////////////////////////////////`
    );

    await confirmContinue({
        contract: "Registry.sol",
        chainId: chainId,
        network: networkName,
        deployerAddress: deployerAddress,
        registryOwner: registryConfig[chainId].owner,
        balance: prettyNum(balance.toString())
    });

    console.log("Deploying Registry...");

    const Registry = await ethers.getContractFactory("Registry");
    const instance = await upgrades.deployProxy(Registry, [
        registryConfig[chainId].owner
    ]);

    // await instance.deploymentTransaction()?.wait(blocksToWait);

    // await verifyContract(instance.target.toString(), [registryConfig[chainId].owner]);

    console.log("Registry deployed to:", instance.target);

    console.log("initializing...", instance.target);
    await instance.initialize(
        registryConfig[chainId].owner
    );
    console.log("Registry initializing!");
  
    return instance.target;
}

// deployRegistry().catch((error) => {
//     console.error(error);
//     process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployRegistry.ts --network sepolia