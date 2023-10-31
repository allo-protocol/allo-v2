import hre from "hardhat";
import { deployDonationVotingMerkleDistributionDirect } from "./deployDonationVotingMerkleDistributionDirect";
import { deployDonationVotingMerkleDistributionVault } from "./deployDonationVotingMerkleDistributionVault";
import { deployImpactStreamStrategy } from "./deployImpactStream";
import { deployRFPCommitteeStrategy } from "./deployRFPCommittee";

export async function deployStrategies() {
  const networkName = hre.network.name;

  console.log(`
    ////////////////////////////////////////////////////////
    Deploy Strategies on Allo V2 contracts to ${networkName}
    ///////////////////////////////////////////////////////
  `);

  // await deployRFPSimpleStrategy();
  await deployRFPCommitteeStrategy();

  // QVBaseStrategy is abstract contract
  // await deployQVBaseStrategy();
  await deployDonationVotingMerkleDistributionDirect();
  await deployDonationVotingMerkleDistributionVault();
  await deployImpactStreamStrategy();
}

deployStrategies().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
