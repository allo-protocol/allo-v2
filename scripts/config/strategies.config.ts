// NOTE: Update this file anytime a new strategy is deployed. use fs to update file on deploy.

type StrategyConfig = {
  [key: string]: {
    name: string;
    version: string;
  };
};

type DeployParams = Record<number, StrategyConfig>;
export const strategyConfig: DeployParams = {
  // Mainnet
  1: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Goerli
  5: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Sepolia
  11155111: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // PGN
  424: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // PGN Sepolia
  58008: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Optimism
  10: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Optimism Goerli
  420: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Celo Mainnet
  42220: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Celo Alfajores
  44787: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Polygon Mainnet
  137: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Mumbai
  80001: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Arbitrum One Mainnet
  42161: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Arbitrum Goerli
  421613: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Base Mainnet
  8453: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
  // Base Testnet Goerli
  84531: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
    },
    "donation-voting-merkle-distribution-vault": {
      name: "DonationVotingMerkleDistributionValutStrategy",
      version: "v1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
    },
  },
};