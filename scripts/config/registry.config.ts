// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  owner: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registry on each network.
export const registryConfig: DeployParams = {
  // Mainnet
  1: {
    owner: "0x34d82D1ED8B4fB6e6A569d6D086A39f9f734107E",
  },
  // Goerli
  5: {
    owner: "0x443dA927D9877C1B7D5E13C092Cb1958D3b90FaE",
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
    owner: "0x791BB7b7e16982BDa029893077EEb4F77A2CD564",
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
    owner: "0xc8c4F1b9980B583E3428F183BA44c65D78C15251",
  },
  // Polygon Mumbai Testnet
  80001: {
    owner: "",
  },
  // Arbitrum One Mainnet
  42161: {
    owner: "0xEfEAB1ea32A5d7c6B1DE6192ee531A2eF51198D9",
  },
  // Arbitrum Goerli
  421613: {
    owner: "",
  },
  // Base Mainnet
  8453: {
    owner: "0x850a5515123f49c298DdF33E581cA01bFF928FEf",
  },
  // Base Testnet Goerli
  84531: {
    owner: "",
  },
};