// import deployStrategies

import { ethers } from "hardhat";
import { permit2Contract } from "../config/strategies.config";
import { deployStrategies } from "./deployStrategies";
import { Validator } from "../utils/Validator";

const deployDonationVoting = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const address = await deployStrategies(
    "DonationVotingMerkleDistributionVaultStrategy",
    "v1",
    {
      types: ["address"],
      values: [permit2Contract[chainId].address],
    },
  );

  const validator = await new Validator(
    "DonationVotingMerkleDistributionVaultStrategy",
    address,
  );

  await validator.validate("PERMIT2", [], permit2Contract[chainId].address);
};

deployDonationVoting().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
