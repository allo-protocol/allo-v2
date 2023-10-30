import * as hre from "hardhat";
import * as dotenv from "dotenv";
import { registryConfig } from "../config/registry.config";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-web3";

dotenv.config();

export async function deployRegistry() {
    const network = await hre.network.config;
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY);

    console.log(`
        ////////////////////////////////////////////////////
                Deploys Registry.sol on ${networkName}
        ////////////////////////////////////////////////////`
    );

    console.table({
        contract: "Registry.sol",
        chainId: chainId,
        network: networkName,
        deployerAddress: deployerAddress.address,
        registryOwner: registryConfig[chainId].owner,
    });

    console.log("Deploying Registry...");

    const deployer = new Deployer(hre, deployerAddress);
    const Registry = await deployer.loadArtifact("Registry");
    const instance = await hre.zkUpgrades.deployProxy(
        deployer.zkWallet, Registry,
        [registryConfig[chainId].owner],
        { initializer: "initialize" }
    );

    console.log("Registry deployed to:", instance.address);

    return instance.address;
}

// deployRegistry().catch((error) => {
//     console.error(error);
//     process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployRegistry.ts --network zksync-testnet --config era.hardhat.config.ts