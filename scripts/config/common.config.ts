type CommonConfig = {
  proxyAdminOwner?: string,
};

type DeployParams = Record<number, CommonConfig>;

export const commonConfig: DeployParams = {
  // Mainnet
  1: {
  },
  // Goerli
  5: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Sepolia
  11155111: {
  },
  // PGN
  424: {
  },
  // PGN Sepolia
  58008: {
  },
  // Optimism
  10: {
  },
  // Optimism Goerli
  420: {
  },
  // Fantom
  250: {
  },
  // Fantom Testnet
  4002: {
  },
  // Celo Mainnet
  42220: {
  },
  // Celo Testnet Alfajores
  44787: {
  },
  // ZkSync Era Mainnet
  324: {
  },
  // ZkSync Era Testnet
  280: {
  },
  // Polygon Mainnet
  137: {
  },
  // Mumbai
  80001: {
  },
  // Arbitrum One
  42161: {
  },
  // Arbitrum Goerli
  421613: {
  },
  // Avalanche Mainnet
  43114: {
  },
  // Avalanche Fuji Testnet
  43113: {
  },
};
