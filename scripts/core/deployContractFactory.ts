const { BigNumber } = require('ethers');
import hre, { ethers } from "hardhat";
import { Validator } from "../utils/Validator";
import {
  Deployments,
  delay,
  verifyContract
} from "../utils/scripts";

export async function deployContractFactory() {
  const network = await ethers.provider.getNetwork();
  const networkName = hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(deployerAddress);

  const deploymentIo = new Deployments(chainId, "contractFactory");

  console.log(`
    ////////////////////////////////////////////////////
        Deploys ContractFactory.sol on ${networkName}
    ////////////////////////////////////////////////////
  `);

  console.table({
    contract: "Deploy ContractFactory.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
    balance: ethers.formatEther(balance),
  });

  console.log("Deploying ContractFactory.sol...");

  const ContractFactory = await ethers.getContractFactory("ContractFactory");

  const feeData = await ethers.provider.getFeeData();

  const instance = await ContractFactory.deploy({
    account: account,
    maxFeePerGas: feeData.maxFeePerGas,
    maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
  });

  await instance.waitForDeployment();

  console.log("ContractFactory deployed to:", instance.target);

  const objToWrite = {
    name: "ContractFactory",
    address: instance.target,
    deployerAddress: deployerAddress,
  };

  deploymentIo.write(objToWrite);
  await delay(20000);
  await verifyContract(instance.target.toString(), []);

  const validator = await new Validator("ContractFactory", instance.target);

  let result;
  await validator.validate("isDeployer", [deployerAddress], "true").then(() => {
    result = instance.target;
  });

  return result;
}

if (require.main === module) {
  deployContractFactory().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

// Note: Deploy script to run in terminal:
// npx hardhat compile --network zkSyncTestnet
// npm hardhat deploy-zksync --script scripts/core/deployContractFactory.ts --network zkSyncTestnet