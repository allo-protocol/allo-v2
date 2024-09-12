// NOTE: Update this file anytime a new strategy is deployed. use fs to update file on deploy.
// NOTE: version v1.0 for failed deployments we use a letter (a,b,c,..) to increment the deployment, not the version.
// version format: v[number].[number][alphabet]
// - update number when strategy is updated
// - update alphabet when strategy has to be redeployed

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
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Goerli
  5: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Sepolia
  11155111: {
    "ltip-hedgey-governor": {
      name: "LTIPHedgeyGovernorStrategy",
      version: "v0.1",
    },
    "ltip-hedgey": {
      name: "LTIPHedgeyStrategy",
      version: "v0.1",
    },
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Optimism
  10: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Optimism Goerli
  420: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
  },
  // Celo Mainnet
  42220: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Celo Alfajores
  44787: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Polygon Mainnet
  137: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Mumbai
  80001: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Arbitrum One Mainnet
  42161: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Arbitrum Sepolia
  421614: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Base Mainnet
  8453: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Base Testnet Goerli
  84531: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Optimism Sepolia
  11155420: {
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1.0",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1.0",
    },
    "qv-simple": {
      name: "QVSimpleStrategy",
      version: "v1.0",
    },
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1.0",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Fuji
  43113: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Avalanche
  43114: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Scroll:
  534352: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Fantom
  250: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Fantom Testnet
  4002: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // ZkSync Mainnet
  324: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // ZkSync Sepolia Testnet
  300: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Filecoin Mainnet
  314: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Filecoin Calibration Testnet
  314159: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Sei Devnet
  713715: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Sei Mainnet
  1329: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Lukso Mainnet
  42: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Lukso Testnet
  4201: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
  },
  // Metis andromeda
  1088: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants": {
      name: "DirectGrantsSimpleStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
  // Gnosis
  100: {
    "donation-voting-merkle-distribution-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v2.1",
    },
    "direct-grants-lite": {
      name: "DirectGrantsLiteStrategy",
      version: "v1.0",
    },
    "direct-allocation": {
      name: "DirectAllocationStrategy",
      version: "v1.1",
    },
  },
};
