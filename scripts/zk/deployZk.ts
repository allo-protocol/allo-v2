import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import * as dotenv from "dotenv";
import * as hre from "hardhat";
import { Wallet } from "zksync-web3";
import { registryConfig } from "../config/registry.config";
import { confirmContinue } from "../utils/scripts";

dotenv.config();

async function main() {
  const networkName = "ZkSync Era Testnet";
  const chainId = Number(280); // ZkSync Era Testnet

  // Initialize the wallet
  const testMnemonic =
    "stick toy mercy cactus noodle company pear crawl tide deny pipe name";
  const zkWallet = new Wallet(process.env.DEPLOYER_PRIVATE_KEY ?? testMnemonic);


  const blocksToWait = hre.network.name === "localhost" ? 0 : 5;

  console.log(`
        ////////////////////////////////////////////////////
                Deploys Registry.sol on ${networkName}
        ////////////////////////////////////////////////////
`);

  await confirmContinue({
    contract: "Registry.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: zkWallet.address,
    registryOwner: registryConfig[chainId].owner,
  });

  const contractName = "Registry";
  console.log("Deploying " + contractName + "...");

  // Create a deployer object
  const deployer = new Deployer(hre, zkWallet);

  const registryArtifact = await deployer.loadArtifact(contractName);
  const deploymentFee = await deployer.estimateDeployFee(registryArtifact, []);

  const registry = await hre.zkUpgrades.deployProxy(
    deployer.zkWallet,
    registryArtifact,
    [registryConfig[chainId].owner]
  );

  await registry.deployed();
  console.log(contractName + " deployed to:", registry.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
