// NOTE: Update this file anytime a new strategy is deployed. use fs to update file on deploy.

type StrategyConfig = {
  [key: string]: {
    address: string;
    name: string;
    version: string;
  };
};

type DeployParams = Record<number, StrategyConfig>;

// NOTE: This will be the version address for each registy on each network.
export const nameConfig: DeployParams = {
  // Mainnet
  1: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Goerli
  5: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "",
      address: "",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
      address: "",
    },
  },
  // Sepolia
  11155111: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1.2",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "v1",
      address: "",
    },
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
      address: "",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
      address: "",
    },
  },
  // PGN
  424: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // PGN Sepolia
  58008: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1.2",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "v1.1",
      address: "",
    },
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
      address: "",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
      address: "",
    },
  },
  // Optimism
  10: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Optimism Goerli
  420: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1.2",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
      address: "",
    },
  },
  // Fantom
  250: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Fantom Testnet
  4002: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1.2",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Celo Mainnet
  42220: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Celo Alfajores
  44787: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // ZkSync Era Mainnet
  324: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // ZkSync Era Testnet
  280: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1.2",
      address: "",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "",
      address: "",
    },
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  }
};
