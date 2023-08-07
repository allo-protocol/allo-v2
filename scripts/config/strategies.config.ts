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
    address: "0x339d087B3ab5DF79c6c3617B2487e5340F2DBE3f",
  },
  // Sepolia
  11155111: {
    address: "0x339d087B3ab5DF79c6c3617B2487e5340F2DBE3f",
  },
  // PGN
  424: {
    address: "",
  },
  // PGN Sepolia
  58008: {
    address: "0x339d087B3ab5DF79c6c3617B2487e5340F2DBE3f",
  },
  // Optimism
  10: {
    address: "",
  },
  // Optimism Goerli
  420: {
    address: "0x339d087B3ab5DF79c6c3617B2487e5340F2DBE3f",
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
    address: "",
  },
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
  },
  // Goerli
  5: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "0x4AB4eF1aa0c2f63FFE77b245E679fb7B38681470",
    },
  },
  // Sepolia
  11155111: {
    "donation-voting": {
      name: "DonationVotingStrategy",
      version: "v1",
      address: "0x4AB4eF1aa0c2f63FFE77b245E679fb7B38681470",
    },
  },
  // PGN
  424: {
    "donation-voting": {
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
      address: "0x4AB4eF1aa0c2f63FFE77b245E679fb7B38681470",
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
      address: "0x4AB4eF1aa0c2f63FFE77b245E679fb7B38681470",
    },
  },
  // Fantom
  250: {
    "donation-voting": {
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
  },
  // Celo Mainnet
  42220: {
    "donation-voting": {
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
};
