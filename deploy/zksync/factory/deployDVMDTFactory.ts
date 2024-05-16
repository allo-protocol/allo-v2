import * as hre from "hardhat";
import { strategyConfig } from "../../../scripts/config/strategies.config";
import { commonConfig } from "../../../scripts/config/common.config";
import { deployStrategyFactories } from "./utils";

export default async function () {
  const network = await hre.network.config;
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["donation-voting-merkle-distribution-direct"];

  await deployStrategyFactories(
    "DVMDTFactory",
    strategyParams.name,
    strategyParams.version,
    [commonConfig[chainId].permit2Address]
  );

};