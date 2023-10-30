import { ethers } from "hardhat";
import { permit2Contract, strategyConfig } from "../config/strategies.config";
import { deployStrategies } from "./deployStrategies";
import { Validator } from "../utils/Validator";

const deployStrategy = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["donation-voting-merkle-distribution-vault"];

  const address = await deployStrategies(
    strategyParams.name,
    strategyParams.version,
    {
      types: ["address"],
      values: [permit2Contract[chainId].address],
    },
  );

  const validator = await new Validator(
    strategyParams.name,
    address,
  );

  await validator.validate("PERMIT2", [], permit2Contract[chainId].address);
};

deployStrategy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
