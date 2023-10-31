import { ethers } from "hardhat";
import { commonConfig } from "../config/common.config";
import { strategyConfig } from "../config/strategies.config";
import { Validator } from "../utils/Validator";
import { deployStrategies } from "./deployStrategies";

export const deployDonationVotingMerkleDistributionVault = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["donation-voting-merkle-distribution-vault"];

  const address = await deployStrategies(
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

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployDonationVotingMerkleDistributionVault().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
