import hre, { ethers } from "hardhat";
import { confirmContinue, prettyNum } from "../utils/script-utils";

export async function deployDeployer() {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const blocksToWait = networkName === "localhost" ? 0 : 5;
  const balance = await ethers.provider.getBalance(deployerAddress);

  console.log(`
    ////////////////////////////////////////////////////
            Deploys Deployer.sol on ${networkName}
    ////////////////////////////////////////////////////`
  );

  await confirmContinue({
    contract: "Deploy Deployer.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
    balance: prettyNum(balance.toString()),
  });

  console.log("Deploying Deployer.sol...");

  const Deployer = await ethers.getContractFactory("Deployer");
  const instance = await Deployer.deploy();

  // await instance.deploymentTransaction()?.wait(blocksToWait);

  console.log("Deployer deployed to:", instance.target);

  return instance.target;
}

// deployDeployer().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployDeployer.ts --network sepolia
