import { deployStrategies } from "./deployStrategies";
import { strategyConfig } from "../config/strategies.config";
import { ethers } from "hardhat";

const deployStrategy = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const strategyParams = strategyConfig[chainId]["qv-base"];

  deployStrategies(strategyParams.name, strategyParams.version);
};

deployStrategy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
