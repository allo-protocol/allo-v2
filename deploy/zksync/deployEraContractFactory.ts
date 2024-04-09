import * as hre from "hardhat";
import * as dotenv from "dotenv";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-ethers";
import { Deployments, verifyContract } from "../../scripts/utils/scripts";

dotenv.config();

export default async function () {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY as string);

  const deploymentIo = new Deployments(chainId, "contractFactory");

  console.log(`
    ////////////////////////////////////////////////////
        Deploys ContractFactory.sol on ${networkName}
    ////////////////////////////////////////////////////`
  );

  console.table({
    contract: "Deploy ContractFactory.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress.address,
  });

  console.log("Deploying ContractFactory.sol...");

  const deployer = new Deployer(hre, deployerAddress);
  const artifact = await deployer.loadArtifact(
    "ContractFactory"
  );

  const instance = await deployer.deploy(artifact, []);
  const CONTRACT_ADDRESS = await instance.getAddress();

  console.log(`${artifact.contractName} was deployed to ${CONTRACT_ADDRESS}`);

  const objToWrite = {
    name: "ContractFactory",
    address: instance.target,
    deployerAddress: deployerAddress.address,
  };
  deploymentIo.write(objToWrite);

  await verifyContract(CONTRACT_ADDRESS, []);
}

// Note: Deploy script to run in terminal:
// npx hardhat compile --network zkSyncTestnet --config era.hardhat.config.ts
// npx hardhat deploy-zksync --network zkSyncTestnet --config era.hardhat.config.ts