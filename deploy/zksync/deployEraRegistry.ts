import * as hre from "hardhat";
import * as dotenv from "dotenv";
import { registryConfig } from "../../scripts/config/registry.config";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-ethers";
import { Deployments, verifyContract } from "../../scripts/utils/scripts";

dotenv.config();

export default async function () {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(
    process.env.DEPLOYER_PRIVATE_KEY as string
  );

  const deployments = new Deployments(chainId, "registry");

  console.log(`
    ////////////////////////////////////////////////////
          Deploys Registry.sol on ${networkName}
    ////////////////////////////////////////////////////`
  );

  const registryParams = registryConfig[chainId];
  if (!registryParams) {
    throw new Error(`Registry params not found for chainId: ${chainId}`);
  }

  console.table({
    contract: "Registry.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress.address,
    registryOwner: registryParams.owner,
  });

  console.log("Deploying Registry...");

  const deployer = new Deployer(hre, deployerAddress);
  const Registry = await deployer.loadArtifact("Registry");
  const instance = await hre.zkUpgrades.deployProxy(
    deployer.zkWallet,
    Registry,
    [registryConfig[chainId].owner],
    { initializer: "initialize" }
  );

  await instance.waitForDeployment();
  const proxyContractAddress = await instance.getAddress();

  console.log("Registry deployed to:", proxyContractAddress);

  const objToWrite = {
    name: "Registry",
    proxy: proxyContractAddress,
    deployerAddress: deployerAddress.address,
    owner: registryParams.owner,
  };

  deployments.write(objToWrite);

  await verifyContract(proxyContractAddress, []);

  return proxyContractAddress;
}

// Note: Deploy script to run in terminal:
// npx hardhat compile --network zkSyncTestnet --config era.hardhat.config.ts
// npx hardhat deploy-zksync --network zkSyncTestnet --config era.hardhat.config.ts --script deployRegistry.ts
