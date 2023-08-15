import { deployStrategies } from "./deployStrategies";

const deployDonationVoting = async () => {
  deployStrategies("DirectGrantsSimpleStrategy", "v1");
};

deployDonationVoting().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
