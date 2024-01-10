import hre, { ethers } from "hardhat";
import {
  delay,
  verifyContract
} from "../utils/scripts";

export async function deployBulkCreation() {
  const network = await ethers.provider.getNetwork();
  const networkName = hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const blocksToWait = networkName === "localhost" ? 0 : 5;
  const balance = await ethers.provider.getBalance(deployerAddress);

  console.log(`
    ////////////////////////////////////////////////////
        Deploys BulkCreation.sol on ${networkName}
    ////////////////////////////////////////////////////
  `);

  console.table({
    contract: "Deploy BulkCreation.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
    balance: ethers.formatEther(balance),
  });

  console.log("Deploying BulkCreation.sol...");

  const BulkCreation = await ethers.getContractFactory("BulkCreation");
  const instance = await BulkCreation.deploy();

  await instance.waitForDeployment();
  await instance.deploymentTransaction()?.wait(blocksToWait);

  console.log("BulkCreation deployed to:", instance.target);


  await delay(20000);
  await verifyContract(instance.target.toString(), []);
}

if (require.main === module) {
  deployBulkCreation().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/deployBulkCreation.ts --network sepolia