import * as hre from "hardhat";
import { deployEraStrategyDirectly } from "./deployEraStrategies";
import { strategyConfig } from "../../../scripts/config/strategies.config";
import { commonConfig } from "../../../scripts/config/common.config";

export default async function () {
  const network = await hre.network.config;
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["donation-voting-merkle-distribution-direct"];

  // const address = await deployEraStrategies(
  //   strategyParams.name,
  //   strategyParams.version,
  //   {
  //     types: ["address"],
  //     values: [commonConfig[chainId].permit2Address],
  //   },
  // );

  await deployEraStrategyDirectly(
    strategyParams.name,
    strategyParams.version,
    [commonConfig[chainId].permit2Address]
  );

};