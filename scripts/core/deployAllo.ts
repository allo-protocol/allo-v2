import hre, { ethers, upgrades } from "hardhat";
import { alloConfig } from "../config/allo.config";
import {
  Deployments,
  confirmContinue,
  getImplementationAddress,
  prettyNum,
  verifyContract,
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

  await confirmContinue({
    contract: "Deploy Allo.sol",
    chainId: chainId,
    network: networkName,
    registry: registryAddress,
    treasury: alloParams.treasury,
    percentFee: alloParams.percentFee,
    baseFee: alloParams.baseFee,
    deployerAddress: deployerAddress,
    balance: prettyNum(balance.toString()),
  });

  console.log("Deploying Allo...");

  const Allo = await ethers.getContractFactory("Allo");
  const instance = await upgrades.deployProxy(Allo, [
    registryAddress,
    alloParams.treasury,
    alloParams.percentFee,
    alloParams.baseFee,
  ]);

  await instance.waitForDeployment();
  await new Promise((r) => setTimeout(r, 20000));

  const implementation = await getImplementationAddress(
    instance.target as string
  );

  console.log("Allo Proxy deployed to:", instance.target);
  console.log("Registry implementation deployed to:", implementation);

  const objToWrite = {
    name: "Allo",
    implementation: implementation,
    proxy: instance.target,
    treasury: alloParams.treasury,
    percentFee: alloParams.percentFee,
    baseFee: alloParams.baseFee,
    registry: registryAddress,
    deployerAddress: deployerAddress,
  };

  deployments.write(objToWrite);

  await verifyContract(implementation, []);
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
// npx hardhat run scripts/deployAllo.ts --network sepolia
