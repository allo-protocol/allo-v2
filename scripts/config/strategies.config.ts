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
};

// NOTE: This will be the version address for each registy on each network.
export const nameConfig: DeployParams = {
  // Mainnet
  1: {
    "direct-grants": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Goerli
  5: {
    "direct-grants": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Sepolia
  11155111: {
    "direct-grants": {
      name: "",
      version: "",
      address: "",
    },
  },
  // PGN
  424: {
    "direct-grants": {
      name: "",
      version: "",
      address: "",
    },
  },
  // PGN Sepolia
  58008: {
    "direct-grants": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Optimism
  10: {
    "direct-grants": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Optimism Goerli
  420: {
    "direct-grants": {
      name: "",
      version: "",
      address: "",
    },
  },
  // Fantom
  250: {
    "direct-grants": {
      name: "",
      version: "",
      address: "",
    },
  },
};
