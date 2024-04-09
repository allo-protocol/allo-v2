import hre, { ethers, upgrades } from "hardhat";
import { alloConfig } from "../config/allo.config";
import { Validator } from "../utils/Validator";
import {
  Deployments,
  getImplementationAddress,
  verifyContract
} from "../utils/scripts";

export async function deployAllo() {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(deployerAddress);

  const deployments = new Deployments(chainId, "allo");

  console.log(`
    ////////////////////////////////////////////////////
            Deploys Allo.sol on ${networkName}
    ////////////////////////////////////////////////////
  `);

  const alloParams = alloConfig[chainId];
  if (!alloParams) {
    throw new Error(`Allo params not found for chainId: ${chainId}`);
  }

  const registryAddress = deployments.getRegistry();

  console.table({
    contract: "Deploy Allo.sol",
    chainId: chainId,
    network: networkName,
    owner: alloParams.owner,
    registry: registryAddress,
    treasury: alloParams.treasury,
    percentFee: alloParams.percentFee,
    baseFee: alloParams.baseFee,
    deployerAddress: deployerAddress,
    balance: ethers.formatEther(balance),
  });

  console.log("Deploying Allo.sol...");

  const feeData = await ethers.provider.getFeeData();

  const Allo = await ethers.getContractFactory("Allo");
  const instance = await upgrades.deployProxy(Allo,
    [
      alloParams.owner,
      registryAddress,
      alloParams.treasury,
      alloParams.percentFee,
      alloParams.baseFee,
    ],
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

  console.log("Allo Proxy deployed to:", instance.target);
  console.log("Registry implementation deployed to:", implementation);
  console.log("Proxy Admin: ", proxyAdmin);
  console.log("Proxy Admin Owner: ", proxyAdminOwner);

  const objToWrite = {
    name: "Allo",
    implementation: implementation,
    proxy: instance.target,
    treasury: alloParams.treasury,
    percentFee: alloParams.percentFee,
    baseFee: alloParams.baseFee,
    registry: registryAddress,
    owner: alloParams.owner,
    deployerAddress: deployerAddress,
    proxyAdmin: proxyAdmin,
    proxyAdminOwner: proxyAdminOwner,
  };

  deployments.write(objToWrite);

  if (implementation) {
    await verifyContract(instance.target.toString(), []);
    await verifyContract(implementation, []);
  }

  const validator = await new Validator("Allo", instance.target);
  await validator.validate("getRegistry", [], registryAddress);
  await validator.validate("getTreasury", [], alloParams.treasury);
  await validator.validate(
    "getPercentFee",
    [],
    alloParams.percentFee.toString(),
  );
  await validator.validate("getBaseFee", [], alloParams.baseFee.toString());
  await validator.validate("owner", [], alloParams.owner.toString());

  return instance.target;
}

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployAllo().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/deployAllo.ts --network sepolia