import hre, { ethers, upgrades } from "hardhat";
import { alloConfig } from "./config/allo.config";
import { confirmContinue, prettyNum } from "./utils/script-utils";

async function main() {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  let account;
  let accountAddress;
  // const blocksToWait = networkName === "localhost" ? 0 : 10;

  account = (await ethers.getSigners())[0];
  accountAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(accountAddress);

  console.log(`This script deploys the Allo contract on ${networkName}`);

  await confirmContinue({
    contract: "Allo",
    chainId: chainId,
    network: networkName,
    account: accountAddress,
    balance: prettyNum(balance.toString()),
  });

  console.log("Deploying Allo...");

  // TODO: Update - move to a settings file.
  const alloParams = alloConfig[chainId];
  if (!alloParams) {
    throw new Error(`Allo params not found for chainId: ${chainId}`);
  }

  const Allo = await ethers.getContractFactory("Allo");
  const instance = await upgrades.deployProxy(Allo, [
    alloParams.registry,
    alloParams.treasury,
    alloParams.feePercentage,
    alloParams.baseFee,
    alloParams.feeSkirtingBountyPercentage,
  ]);

  console.log("Allo deployed to:", instance.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployAllo.ts --network sepolia
