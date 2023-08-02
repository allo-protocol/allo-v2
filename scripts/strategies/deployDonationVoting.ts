// import deployStrategies

import { deployStrategies } from "./deployStrategies";

const deployDonationVoting = async () => {
  deployStrategies("DonationVotingStrategy", "v1");
};

deployDonationVoting().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
