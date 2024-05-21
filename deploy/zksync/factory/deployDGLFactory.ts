import * as hre from "hardhat";
import { strategyConfig } from "../../../scripts/config/strategies.config";
import { deployStrategyFactories } from "./utils";

export default async function () {
  const network = await hre.network.config;
  const chainId = Number(network.chainId);
  const strategyParams = strategyConfig[chainId]["direct-grants-lite"];

  await deployStrategyFactories(
    "DGLFactory",
    strategyParams.name,
    strategyParams.version
  );
};