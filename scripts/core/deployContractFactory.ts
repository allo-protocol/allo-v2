import hre, { ethers } from "hardhat";
import { confirmContinue, prettyNum, verifyContract } from "../utils/scripts";

export async function deployContractFactory() {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const blocksToWait = networkName === "localhost" ? 0 : 5;
  const balance = await ethers.provider.getBalance(deployerAddress);

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

  const ContractFactory = await ethers.getContractFactory("ContractFactory");
  const instance = await ContractFactory.deploy();

  console.log("ContractFactory deployed to:", instance.target);

  // await verifyContract(instance.target.toString());

  return instance.target;
}

// deployContractFactory().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployContractFactory.ts --network sepolia
