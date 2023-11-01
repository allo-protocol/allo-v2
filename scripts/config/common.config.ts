type CommonConfig = {
  proxyAdminOwner?: string,
  permit2Address: string,
};

type DeployParams = Record<number, CommonConfig>;

export const commonConfig: DeployParams = {
  // Mainnet
  1: {
    proxyAdminOwner: "0x34d82D1ED8B4fB6e6A569d6D086A39f9f734107E",
    permit2Address: "",
  },
  // Goerli
  5: {
    proxyAdminOwner: "0x443dA927D9877C1B7D5E13C092Cb1958D3b90FaE",
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
    proxyAdminOwner: "0x791BB7b7e16982BDa029893077EEb4F77A2CD564",
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
    proxyAdminOwner: "0xc8c4F1b9980B583E3428F183BA44c65D78C15251",
    permit2Address: "",
  },
  // Mumbai
  80001: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Arbitrum One
  42161: {
    proxyAdminOwner: "0xEfEAB1ea32A5d7c6B1DE6192ee531A2eF51198D9",
    permit2Address: "",
  },
  // Arbitrum Goerli
  421613: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Base Mainnet
  8453: {
    proxyAdminOwner: "0x850a5515123f49c298DdF33E581cA01bFF928FEf",
    permit2Address: "",
  },
  // Base Testnet Goerli
  84531: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
};
