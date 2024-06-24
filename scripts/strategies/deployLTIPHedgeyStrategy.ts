import { deployStrategies, deployStrategyDirectly } from "./deployStrategies";
import { strategyConfig } from "../config/strategies.config";
import { ethers } from "hardhat";

export const deployLTIPHedgeyStrategy = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const strategyParams = strategyConfig[chainId]["ltip-hedgey"];

  // await deployStrategies(strategyParams.name, strategyParams.version);
  await deployStrategyDirectly(strategyParams.name, strategyParams.version);

  //To verify
  // npx hardhat verify --network sepolia [RETURNED_ADDRESS] "0x1133eA7Af70876e64665ecD07C0A0476d09465a1" "LTIPHedgeyStrategyv0.1"
};

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployLTIPHedgeyStrategy().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}