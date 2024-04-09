import hre, { ethers, upgrades } from "hardhat";
import { registryConfig } from "../config/registry.config";
import { Validator } from "../utils/Validator";
import {
  Deployments,
  getImplementationAddress,
  verifyContract
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

  const registryParams = registryConfig[chainId];
  if (!registryParams) {
    throw new Error(`Registry params not found for chainId: ${chainId}`);
  }

  console.table({
    contract: "Registry.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
    registryOwner: registryParams.owner,
    balance: ethers.formatEther(balance),
  });

  console.log("Deploying Registry...");

  const feeData = await ethers.provider.getFeeData();

  const Registry = await ethers.getContractFactory("Registry");
  const instance = await upgrades.deployProxy(
    Registry,
    [registryParams.owner],
    {
      txOverrides: {
        maxFeePerGas: feeData.maxFeePerGas,
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
      }
    }
  );

  await instance.waitForDeployment();
  
  let implementation;
  try {
    implementation = await getImplementationAddress(
      instance.target as string,
    );
  } catch (error) {
    console.error("Error getting implementation address: ", error);
  }

  const proxyAdmin = await upgrades.erc1967.getAdminAddress(instance.target as string);
  let proxyAdminOwner = account.address;

  console.log("Registry proxy deployed to:", instance.target);
  console.log("Registry implementation deployed to:", implementation);
  console.log("Proxy Admin: ", proxyAdmin);
  console.log("Proxy Admin Owner: ", proxyAdminOwner);

  const objToWrite = {
    name: "Registry",
    implementation: implementation,
    proxy: instance.target,
    deployerAddress: deployerAddress,
    owner: registryParams.owner,
    proxyAdmin: proxyAdmin,
    proxyAdminOwner: proxyAdminOwner,
  };

  deployments.write(objToWrite);

  if (implementation) {
    await verifyContract(instance.target.toString(), []);
    await verifyContract(implementation, []);
  }

  const validator = await new Validator("Registry", instance.target);
  const ownerRole =
    "0x815b5a78dc333d344c7df9da23c04dbd432015cc701876ddb9ffe850e6882747"; //keccak256("ALLO_OWNER");

  await validator.validate(
    "hasRole",
    [ownerRole, registryParams.owner],
    "true",
  );

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