import hre, { ethers } from "hardhat";

require("hardhat-deploy");
require("hardhat-deploy-ethers");

import { Validator } from "../../scripts/utils/Validator";
import { Deployments, delay, verifyContract } from "../../scripts/utils/scripts";

module.exports = async ({ deployments }) => {
  const { deploy } = deployments;
  const network = await ethers.provider.getNetwork();
  const networkName = hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const blocksToWait = networkName === "localhost" ? 0 : 5;
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

  const instance = await deploy("ContractFactory", {
    from: deployerAddress,
    args: [],
    log: true,
});

  await instance.waitForDeployment();
  await instance.deploymentTransaction()?.wait(blocksToWait);

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

}

// Note: Deploy script to run in terminal:
// npx hardhat compile --config config/fvm.hardhat.config.ts --network filecoin-calibration
// npx hardhat deploy --config config/fvm.hardhat.config.ts --show-stack-traces --network filecoin-calibration