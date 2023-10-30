type CommonConfig = {
  proxyAdminOwner?: string,
};

type DeployParams = Record<number, CommonConfig>;

export const commonConfig: DeployParams = {
  // Mainnet
  1: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Goerli
  5: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Sepolia
  11155111: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // PGN
  424: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // PGN Sepolia
  58008: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Optimism
  10: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Optimism Goerli
  420: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Celo Mainnet
  42220: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Celo Testnet Alfajores
  44787: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Polygon Mainnet
  137: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Mumbai
  80001: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Arbitrum One
  42161: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
  // Arbitrum Goerli
  421613: {
    proxyAdminOwner: "0x66Be9a4412ac7a10eF46298B2cA72B42C95e80b4",
  },
};
