import * as hre from "hardhat";
import { deployEraStrategies } from "./deployEraStrategies";
import { strategyConfig } from "../../scripts/config/strategies.config";

export default async function () {
  const network = await hre.network.config;
  const chainId = Number(network.chainId);
  const strategyParams = strategyConfig[chainId]["direct-grants"];

  await deployEraStrategies(strategyParams.name, strategyParams.version);
};