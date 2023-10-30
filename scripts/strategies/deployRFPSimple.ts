import { deployStrategies } from "./deployStrategies";
import { strategyConfig } from "../config/strategies.config";
import { ethers } from "hardhat";

export const deployRFPSimpleStrategy = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const strategyParams = strategyConfig[chainId]["rfp-simple"];

  deployStrategies(strategyParams.name, strategyParams.version);
};

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployRFPSimpleStrategy().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
};