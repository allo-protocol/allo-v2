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
      name: "",
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
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Sepolia
  11155111: {
    "direct-grants-simple": {
      name: "DirectGrantsSimpleStrategy",
      version: "v1.1",
      address: "",
    },
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1.2",
      address: "",
    },
    "rfp-simple": {
      name: "RFPSimpleStrategy",
      version: "v1",
      address: "",
    },
  },
  // PGN
  424: {
    "donation-voting": {
      name: "",
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
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Optimism
  10: {
    "donation-voting": {
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
    "rfp-simple": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Fantom
  250: {
    "donation-voting": {
      name: "",
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
      name: "",
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
      name: "",
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
  },
  // ZkSync Era Mainnet
  324: {
    "donation-voting": {
      name: "",
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
      name: "",
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
