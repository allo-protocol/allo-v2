import { ethers } from "hardhat";
import { deployEraStrategies } from "./deployEraStrategies";
import { strategyConfig } from "../../scripts/config/strategies.config";
import { commonConfig } from "../../scripts/config/common.config";
import { Validator } from "../../scripts/utils/Validator";

export const deployEraDonationVotingMerkleDistributionDirect = async () => {
  const network = await ethers.provider.getNetwork();
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

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployEraDonationVotingMerkleDistributionDirect().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
