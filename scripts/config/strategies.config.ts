// NOTE: Update this file anytime a new strategy is deployed. use fs to update file on deploy.

type StrategyConfig = {
  [key: string]: {
    address: string;
    name: string;
    version: string;
  };
};

type DeployParams = Record<number, StrategyConfig>;

type DeployerConfig = {
  [key: number]: { address: string };
};

export const deployerContractAddress: DeployerConfig = {
  // Mainnet
  1: {
    address: "",
  },
  // Goerli
  5: {
    address: "0x737b811828B34838e2188c59cfF72BD1019A1070",
  },
  // Sepolia
  11155111: {
    address: "0x737b811828B34838e2188c59cfF72BD1019A1070",
  },
  // PGN
  424: {
    address: "",
  },
  // PGN Sepolia
  58008: {
    address: "0x737b811828B34838e2188c59cfF72BD1019A1070",
  },
  // Optimism
  10: {
    address: "",
  },
  // Optimism Goerli
  420: {
    address: "0x737b811828B34838e2188c59cfF72BD1019A1070",
  },
  // Fantom
  250: {
    address: "",
  },
  // Fantom Testnet
  4002: {
    address: "",
  },
  // Celo Mainnet
  42220: {
    address: "",
  },
  // Celo Alfajores
  44787: {
    address: "0x737b811828B34838e2188c59cfF72BD1019A1070",
  },
  // ZkSync Era Mainnet
  324: {
    address: "",
  },
  // ZkSync Era Testnet
  280: {
    address: "",
  },
};

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
      address: "0x81Abcb682cc61c463Cdbe1Ef1804CbEfC1d54d7f",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1",
      address: "0x4a41F242cA053DB83F7D45C92a3757fb94bD65A8",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "0x8253782db9cA148A07c19ca36A4fA0D02f45A2ca",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "v1",
      address: "0xB42C26e4029e932CDd53981f7CbefF89e74F03c2",
    },
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
      address: "0x03FA47235fAF670c72dD765A4eE55Bd332308029",
    },
    "rfp-committee": {
      name: "RFPCommitteeStrategy",
      version: "v1",
      address: "0x9DB5B54a4f63124428e293b37A81D4e3bcC2F222",
    },
    "qv-impact-stream": {
      name: "QVImpactStreamStrategy",
      version: "v1",
      address: "0x7Bb23D29BA83D92EACD99e17B32a2794A1A10cdd",
    },
  },
  // Sepolia
  11155111: {
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
};
