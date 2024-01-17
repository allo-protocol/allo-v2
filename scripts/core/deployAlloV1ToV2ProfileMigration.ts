import hre, { ethers } from "hardhat";
import {
  delay,
  verifyContract
} from "../utils/scripts";

export async function deployAlloV1ToV2ProfileMigration() {
  const network = await ethers.provider.getNetwork();
  const networkName = hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const blocksToWait = networkName === "localhost" ? 0 : 5;
  const balance = await ethers.provider.getBalance(deployerAddress);

  console.log(`
    ////////////////////////////////////////////////////
        Deploys AlloV1ToV2ProfileMigration.sol on ${networkName}
    ////////////////////////////////////////////////////
  `);

  console.table({
    contract: "Deploy AlloV1ToV2ProfileMigration.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
    balance: ethers.formatEther(balance),
  });

  console.log("Deploying AlloV1ToV2ProfileMigration.sol...");

  const AlloV1ToV2ProfileMigration = await ethers.getContractFactory("AlloV1ToV2ProfileMigration");
  const instance = await AlloV1ToV2ProfileMigration.deploy();

  await instance.waitForDeployment();
  await instance.deploymentTransaction()?.wait(blocksToWait);

  console.log("AlloV1ToV2ProfileMigration deployed to:", instance.target);


  await delay(20000);
  await verifyContract(instance.target.toString(), []);
}

if (require.main === module) {
  deployAlloV1ToV2ProfileMigration().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/deployAlloV1ToV2ProfileMigration.ts --network sepolia