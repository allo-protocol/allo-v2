import * as hre from "hardhat";
import { deployEraStrategies } from "./deployEraStrategies";
import { strategyConfig } from "../../scripts/config/strategies.config";
import { commonConfig } from "../../scripts/config/common.config";
import { Validator } from "../../scripts/utils/Validator";

export default async function () {
  const network = await hre.network.config;
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["donation-voting-merkle-distribution-direct"];

  const address = await deployEraStrategies(
    strategyParams.name,
    strategyParams.version,
    {
      types: ["address"],
      values: [commonConfig[chainId].permit2Address],
    },
  );

  const validator = await new Validator(
    strategyParams.name,
    address,
  );

  await validator.validate("PERMIT2", [], commonConfig[chainId].permit2Address);
};