import { ethers } from "hardhat";
import { permit2Contract, strategyConfig } from "../config/strategies.config";
import { deployStrategies } from "./deployStrategies";
import { Validator } from "../utils/Validator";

export const deployDonationVotingMerkleDistributionDirect = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["donation-voting-merkle-distribution-direct"];

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

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployDonationVotingMerkleDistributionDirect().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
