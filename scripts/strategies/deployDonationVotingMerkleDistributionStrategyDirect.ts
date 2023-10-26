// import deployStrategies

import { ethers } from "hardhat";
import { deployStrategies } from "./deployStrategies";
import { permit2Contract } from "../config/strategies.config";
import { Validator } from "../utils/Validator";

const deployDonationVoting = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const address = await deployStrategies(
    "DonationVotingMerkleDistributionDirectTransferStrategy",
    "v1",
    {
      types: ["address"],
      values: [permit2Contract[chainId].address],
    },
  );

  const validator = await new Validator(
    "DonationVotingMerkleDistributionDirectTransferStrategy",
    address,
  );

  await validator.validate("PERMIT2", [], permit2Contract[chainId].address);
};

deployDonationVoting().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
