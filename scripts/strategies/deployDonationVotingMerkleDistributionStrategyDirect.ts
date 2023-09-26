// import deployStrategies

import { deployStrategies } from "./deployStrategies";

const deployDonationVoting = async () => {
  deployStrategies("DonationVotingMerkleDistributionDirectTransferStrategy", "v1.1");
};

deployDonationVoting().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
