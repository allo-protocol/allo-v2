import * as hre from "hardhat";
import { registryConfig } from "../config/registry.config";
import { confirmContinue, prettyNum } from "../utils/scripts";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-web3";


export async function deployRegistry() {
    const network = await hre.ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY);
    const balance = await hre.ethers.provider.getBalance(deployerAddress);

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

    const deployer = new Deployer(hre, deployerAddress);
    const Registry = await deployer.loadArtifact("Registry");
    const instance = await hre.zkUpgrades.deployProxy(
        deployer.zkWallet, Registry,
        [registryConfig[chainId].owner],
        { initializer: "initialize" }
    );

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
// npx hardhat run scripts/deployRegistry.ts --network zksync-testnet --config era.hardhat.config.ts