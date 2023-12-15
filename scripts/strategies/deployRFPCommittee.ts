import { deployStrategies } from "./deployStrategies";
import { strategyConfig } from "../config/strategies.config";
import { ethers } from "hardhat";

export const deployRFPCommitteeStrategy = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const strategyParams = strategyConfig[chainId]["rfp-committee"];

  await deployStrategies(strategyParams.name, strategyParams.version);
};

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployRFPCommitteeStrategy().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}