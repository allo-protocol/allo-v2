import * as hre from "hardhat";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-web3";

import { confirmContinue, prettyNum, verifyContract } from "../utils/scripts";

export async function deployContractFactory() {
  const network = await hre.ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY);
  const balance = await hre.ethers.provider.getBalance(deployerAddress);

  console.log(`
    ////////////////////////////////////////////////////
        Deploys ContractFactory.sol on ${networkName}
    ////////////////////////////////////////////////////`
  );

  await confirmContinue({
    contract: "Deploy ContractFactory.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
    balance: prettyNum(balance.toString()),
  });

  console.log("Deploying ContractFactory.sol...");

  const deployer = new Deployer(hre, deployerAddress);
  const ContractFactory = await deployer.loadArtifact(
    "ContractFactory"
  );

  const instance = await deployer.deploy(
    ContractFactory,
    []
  );
  console.log("ContractFactory deployed to:", instance.target);

  // await verifyContract(instance.target.toString());

  return instance.target;
}

// deployContractFactory().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployContractFactory.ts --network zksync-testnet --config era.hardhat.config.ts
