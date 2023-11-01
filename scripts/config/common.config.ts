type CommonConfig = {
  proxyAdminOwner?: string,
  permit2Address: string,
};

type DeployParams = Record<number, CommonConfig>;

export const commonConfig: DeployParams = {
  // Mainnet
  1: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Goerli
  5: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Sepolia
  11155111: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // PGN
  424: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // PGN Sepolia
  58008: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Optimism
  10: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Optimism Goerli
  420: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Celo Mainnet
  42220: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Celo Testnet Alfajores
  44787: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Polygon Mainnet
  137: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Mumbai
  80001: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Arbitrum One
  42161: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Arbitrum Goerli
  421613: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
};
