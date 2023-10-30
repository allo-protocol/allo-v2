// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  owner: string;
  proxyAdminOwner?: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registry on each network.
export const registryConfig: DeployParams = {
  // Mainnet
  1: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Goerli
  5: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Sepolia
  11155111: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // PGN
  424: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // PGN Sepolia
  58008: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Optimism
  10: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Optimism Goerli
  420: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Fantom
  250: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Fantom Testnet
  4002: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Celo Mainnet
  42220: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Celo Testnet Alfajores
  44787: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // zkSync-testnet
  280: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // zkSync-mainnet
  324: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Polygon Mainnet
  137: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Polygon Mumbai Testnet
  80001: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Arbitrum One Mainnet
  42161: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Arbitrum Goerli
  421613: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Base Mainnet
  8453: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
  // Base Testnet Goerli
  84531: {
    owner: "0x5078a23B2C95e1B2f7C2Cee9F1Fb5534d473E781",
  },
};