import hre, { ethers } from "hardhat";
import { alloConfig } from "../config/allo.config";
import { deployContractUsingFactory } from "../utils/deployProxy";
import { confirmContinue, prettyNum } from "../utils/scripts";

export async function deployStrategies(strategyName: string, version: string) {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  // const blocksToWait = networkName === "localhost" ? 0 : 5;
  const balance = await ethers.provider.getBalance(deployerAddress);

  console.log(`
    ////////////////////////////////////////////////////
      Deploys ${strategyName}.sol on ${networkName}
    ////////////////////////////////////////////////////
  `);

  await confirmContinue({
    contract: `${strategyName}.sol`,
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
    balance: prettyNum(balance.toString()),
  });

  console.log(`Deploying ${strategyName}.sol`);

  deployContractUsingFactory(strategyName, version, {
    types: ["address", "string"],
    values: [alloConfig[chainId].alloProxy, strategyName + version],
  });
}

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployStrategies.ts --network sepolia
