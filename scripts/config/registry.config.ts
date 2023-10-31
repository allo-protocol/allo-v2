// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  owner: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registry on each network.
export const registryConfig: DeployParams = {
  // Mainnet
  1: {
    owner: "",
  },
  // Goerli
  5: {
    owner: "",
  },
  // Sepolia
  11155111: {
    owner: "",
  },
  // PGN
  424: {
    owner: "",
  },
  // PGN Sepolia
  58008: {
    owner: "",
  },
  // Optimism
  10: {
    owner: "",
  },
  // Optimism Goerli
  420: {
    owner: "",
  },
  // Celo Mainnet
  42220: {
    owner: "",
  },
  // Celo Testnet Alfajores
  44787: {
    owner: "",
  },
  // Polygon Mainnet
  137: {
    owner: "",
  },
  // Polygon Mumbai Testnet
  80001: {
    owner: "",
  },
  // Arbitrum One Mainnet
  42161: {
    owner: "",
  },
  // Arbitrum Goerli
  421613: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Base Mainnet
  8453: {
    owner: "",
  },
  // Base Testnet Goerli
  84531: {
    owner: "",
  },
};