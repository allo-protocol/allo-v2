import hre from "hardhat";
import { deployDonationVotingMerkleDistributionDirect } from "./deployDonationVotingMerkleDistributionDirect";
import { deployDonationVotingMerkleDistributionVault } from "./deployDonationVotingMerkleDistributionVault";
import { deployImpactStreamStrategy } from "./deployImpactStream";
import { deployQVSimpleStrategy } from "./deployQVSimple";
import { deployRFPCommitteeStrategy } from "./deployRFPCommittee";
import { deployRFPSimpleStrategy } from "./deployRFPSimple";

export async function deployStrategies() {
  const networkName = hre.network.name;

  console.log(`
    ////////////////////////////////////////////////////////
    Deploy Strategies on Allo V2 contracts to ${networkName}
    ///////////////////////////////////////////////////////
  `);

  await deployQVSimpleStrategy();
  await deployRFPSimpleStrategy();
  await deployRFPCommitteeStrategy();
  await deployDonationVotingMerkleDistributionDirect();
  await deployDonationVotingMerkleDistributionVault();
  await deployImpactStreamStrategy();
}

deployStrategies().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
