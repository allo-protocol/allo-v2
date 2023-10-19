import hre, { ethers, upgrades } from "hardhat";
import { registryConfig } from "../config/registry.config";
import {
    Deployments,
    confirmContinue,
    getImplementationAddress,
    prettyNum,
    verifyContract,
} from "../utils/scripts";

export async function deployRegistry() {
  const network = await ethers.provider.getNetwork();
  const networkName = hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(deployerAddress);

  const deployments = new Deployments(chainId, "registry");

  console.log(`
    ////////////////////////////////////////////////////
            Deploys Registry.sol on ${networkName}
    ////////////////////////////////////////////////////
  `);

  await confirmContinue({
    contract: "Registry.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
    registryOwner: registryConfig[chainId].owner,
    balance: prettyNum(balance.toString()),
  });

  console.log("Deploying Registry...");

  const Registry = await ethers.getContractFactory("Registry");
  const instance = await upgrades.deployProxy(Registry, [
    registryConfig[chainId].owner,
  ]);

  await instance.waitForDeployment();
  await new Promise((r) => setTimeout(r, 20000));

  const implementation = await getImplementationAddress(
    instance.target as string
  );

  console.log("Registry proxy deployed to:", instance.target);
  console.log("Registry implementation deployed to:", implementation);

  const objToWrite = {
    registryImplementation: implementation,
    registryProxy: instance.target,
    deployerAddress: deployerAddress,
    owner: registryConfig[chainId].owner,
  };

  deployments.write(objToWrite);

  await verifyContract(implementation, []);
  return instance.target;
}

if (require.main === module) {
  deployRegistry().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/deployRegistry.ts --network sepolia
