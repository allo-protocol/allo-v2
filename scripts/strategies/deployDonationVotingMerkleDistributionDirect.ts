import { ethers } from "hardhat";
import { commonConfig } from "../config/common.config";
import { strategyConfig } from "../config/strategies.config";
import { Validator } from "../utils/Validator";
import { deployStrategies, deployStrategyDirectly } from "./deployStrategies";

export const deployDonationVotingMerkleDistributionDirect = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["donation-voting-merkle-distribution-direct"];

  const address = await deployStrategies(
    strategyParams.name,
    strategyParams.version,
    true,
    {
      types: ["address"],
      values: [commonConfig[chainId].permit2Address],
    },
  );

  // const validator = await new Validator(
  //   strategyParams.name,
  //   address,
  // );

  // await validator.validate("PERMIT2", [], commonConfig[chainId].permit2Address);

  // await deployStrategyDirectly(
  //   strategyParams.name,
  //   strategyParams.version,
  //   [commonConfig[chainId].permit2Address],
  //   true,
  // );

};

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployDonationVotingMerkleDistributionDirect().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
