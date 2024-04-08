import { ethers } from "hardhat";
import { deployEraStrategies } from "./deployEraStrategies";
import { strategyConfig } from "../../scripts/config/strategies.config";

export const deployEraDirectGrants = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["direct-grants"];

  await deployEraStrategies(strategyParams.name, strategyParams.version);
};

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployEraDirectGrants().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
