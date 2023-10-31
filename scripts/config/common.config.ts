type CommonConfig = {
  proxyAdminOwner?: string,
};

type DeployParams = Record<number, CommonConfig>;

export const commonConfig: DeployParams = {
  // Mainnet
  1: {
    proxyAdminOwner: "",
  },
  // Goerli
  5: {
    proxyAdminOwner: "",
  },
  // Sepolia
  11155111: {
    proxyAdminOwner: "",
  },
  // PGN
  424: {
    proxyAdminOwner: "",
  },
  // PGN Sepolia
  58008: {
    proxyAdminOwner: "",
  },
  // Optimism
  10: {
    proxyAdminOwner: "",
  },
  // Optimism Goerli
  420: {
    proxyAdminOwner: "",
  },
  // Celo Mainnet
  42220: {
    proxyAdminOwner: "",
  },
  // Celo Testnet Alfajores
  44787: {
    proxyAdminOwner: "",
  },
  // Polygon Mainnet
  137: {
    proxyAdminOwner: "",
  },
  // Mumbai
  80001: {
    proxyAdminOwner: "",
  },
  // Arbitrum One
  42161: {
    proxyAdminOwner: "",
  },
  // Arbitrum Goerli
  421613: {
    proxyAdminOwner: "",
  },
};
