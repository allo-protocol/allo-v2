// import * as hre from "hardhat";
// import dotenv from "dotenv";
// import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
// import { Wallet } from "zksync-ethers";
import { deployContract } from "./utils";

// dotenv.config();

export default async function() {
  const contractArtifactName = "ContractFactory";
  const constructorArgs: [] = [];

  await deployContract(contractArtifactName, constructorArgs);
}

// npx hardhat run --network zksync-testnet scripts/era/deployContractFactory.ts 
//  npx hardhat deploy-zksync --network zksync-testnet --script deployContractFactory.ts

// export async function deployContractFactory() {
//   const network = await hre.network.config;
//   const networkName = await hre.network.name;
//   const chainId = Number(network.chainId);

//   const wallet = new Wallet(process.env.DEPLOYER_PRIVATE_KEY as string);

//   console.log(`
//     ////////////////////////////////////////////////////
//         Deploys ContractFactory.sol on ${networkName}
//     ////////////////////////////////////////////////////`);

//   console.table({
//     contract: "Deploy ContractFactory.sol",
//     chainId: chainId,
//     network: networkName,
//     deployerAddress: wallet.address,
//   });

//   console.log("Deploying ContractFactory.sol...");

//   const deployer = new Deployer(hre, wallet.address);
//   const ContractFactory = await deployer.loadArtifact("ContractFactory");

//   const instance = await deployer.deploy(ContractFactory, []);
//   console.log("ContractFactory deployed to:", instance.address);

//   // await verifyContract(instance.target.toString());

//   return instance.address;
// }

// deploy().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployContractFactory.ts --network zksync-testnet --config era.hardhat.config.ts
