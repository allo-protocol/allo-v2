import hre from "hardhat";
import { deployDonationVotingMerkleDistributionDirect } from "./deployDonationVotingMerkleDistributionDirect";
import { deployDonationVotingMerkleDistributionVault } from "./deployDonationVotingMerkleDistributionVault";
import { deployRFPSimpleStrategy } from "./deployRFPSimple";
import { deployRFPCommitteeStrategy } from "./deployRFPCommittee";
import { deployImpactStreamStrategy } from "./deployImpactStream";
import { deployQVBaseStrategy } from "./deployQVBase";

export async function deployStrategies() {
  const networkName = hre.network.name;

  console.log(`
    ////////////////////////////////////////////////////////
    Deploy Strategies on Allo V2 contracts to ${networkName}
    ///////////////////////////////////////////////////////
  `);

  await deployRFPSimpleStrategy();
  await deployRFPCommitteeStrategy();
  await deployQVBaseStrategy();
  await deployDonationVotingMerkleDistributionDirect();
  await deployDonationVotingMerkleDistributionVault();
  await deployImpactStreamStrategy();
}

deployStrategies().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
