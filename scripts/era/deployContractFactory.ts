import * as hre from "hardhat";
import * as dotenv from "dotenv";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-web3";

dotenv.config();

export async function deployContractFactory() {

    const network = await hre.network.config;
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY);

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
  const ContractFactory = await deployer.loadArtifact(
    "ContractFactory"
  );

  const instance = await deployer.deploy(
    ContractFactory,
    []
  );
  console.log("ContractFactory deployed to:", instance.address);

  // await verifyContract(instance.target.toString());

  return instance.address;
}

// deployContractFactory().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployContractFactory.ts --network zksync-testnet --config era.hardhat.config.ts
