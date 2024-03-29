import { ethers } from "hardhat";
import { strategyConfig } from "../config/strategies.config";
import { deployStrategies } from "./deployStrategies";

export const deployDirectGrants = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["direct-grants"];

  await deployStrategies(strategyParams.name, strategyParams.version);
};

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployDirectGrants().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
