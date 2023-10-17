import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import * as dotenv from "dotenv";
import * as hre from "hardhat";
import { Wallet } from "zksync-web3";
import { registryConfig } from "../config/registry.config";
import { confirmContinue } from "../utils/scripts";

dotenv.config();

export async function deployRegistry() {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerWallet = new Wallet(process.env.DEPLOYER_PRIVATE_KEY ?? "");
  const registryOwner = registryConfig[chainId].owner;

  console.log(`
        ////////////////////////////////////////////////////
                Deploys Registry.sol on ${networkName}
        ////////////////////////////////////////////////////`);
  await confirmContinue({
    contract: "Registry.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerWallet.address,
    registryOwner: registryOwner,
  });

  console.log("Deploying Registry...");

  const deployer = new Deployer(hre, deployerWallet);
  const Registry = await deployer.loadArtifact("Registry");
  const instance = await hre.zkUpgrades.deployProxy(
    deployer.zkWallet,
    Registry,
    [registryOwner],
    { initializer: "initialize" }
  );
  console.log("Registry deployed to:", instance.address);
}

deployRegistry().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/era/deployRegistry.ts --network zksync-testnet --config era.hardhat.config.ts
