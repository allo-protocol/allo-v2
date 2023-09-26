// NOTE: Update this file anytime a new strategy is deployed.

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
    address: "",
  },
  // Sepolia
  11155111: {
    address: "0xa5791f9461A4385029e6d0E7aeF5ebD8DC6429e5",
  },
  // PGN
  424: {
    address: "",
  },
  // PGN Sepolia
  58008: {
    address: "0xa5791f9461A4385029e6d0E7aeF5ebD8DC6429e5",
  },
  // Optimism
  10: {
    address: "",
  },
  // Optimism Goerli
  420: {
    address: "0xa5791f9461A4385029e6d0E7aeF5ebD8DC6429e5",
  },
  // Fantom
  250: {
    address: "",
  },
  // Fantom Testnet
  4002: {
    address: "0xa5791f9461A4385029e6d0E7aeF5ebD8DC6429e5",
  },
  // Celo Mainnet
  42220: {
    address: "",
  },
  // Celo Alfajores
  44787: {
    address: "0xa5791f9461A4385029e6d0E7aeF5ebD8DC6429e5",
  },
  // ZkSync Era Mainnet
  324: {
    address: "",
  },
  // ZkSync Era Testnet
  280: {
    address: "",
  }
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
  // Sepolia
  11155111: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1.2",
      address: "0xBE24d316223162E71B1CdBbE959B48f5395EDa33",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1.1",
      address: "0xdf14232C92af3dC378E112DD3F4a57c9eebcDBdE",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1",
      address: "0x44E214dD51C625Ae17f161f66D2dB75B5441470c",
    },
    "donation-voting-vault": {
      name: "DonationVotingMerkleDistributionVaultStrategy",
      version: "v1",
      address: "0xAc029EA37F8748cedE980349b804149dc1542839",
    },
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
      address: "0xf1e9C93B52Ea14034219D88d4Bc5390f238Ce945",
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
      address: "0xBE24d316223162E71B1CdBbE959B48f5395EDa33",
    },
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1.1",
      address: "0xdf14232C92af3dC378E112DD3F4a57c9eebcDBdE",
    },
    "donation-voting-direct": {
      name: "DonationVotingMerkleDistributionDirectTransferStrategy",
      version: "v1.1",
      address: "0x1FF19ec3eF402fb7Fb12349c686126e21E52EacA",
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
      address: "0xBE24d316223162E71B1CdBbE959B48f5395EDa33",
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
