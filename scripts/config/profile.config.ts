type ProfileConfig = {
  v1RegistryAddress: string;
};

type ProfileParams = Record<number, ProfileConfig>;

export const profileConfig: ProfileParams = {
  // Mainnet
  1: {
    v1RegistryAddress: "0x03506eD3f57892C85DB20C36846e9c808aFe9ef4",
  },
  // Goerli
  5: {
    v1RegistryAddress: "0x9C789Ad2457A605a0ea1aaBEEf16585633530069",
  },
  // Sepolia
  11155111: {
    v1RegistryAddress: "",
  },
  // PGN
  424: {
    v1RegistryAddress: "0xDF9BF58Aa1A1B73F0e214d79C652a7dd37a6074e",
  },
  // PGN Sepolia
  58008: {
    v1RegistryAddress: "",
  },
  // Optimism
  10: {
    v1RegistryAddress: "0x8e1bD5Da87C14dd8e08F7ecc2aBf9D1d558ea174",
  },
  // Celo Mainnet
  42220: {
    v1RegistryAddress: "",
  },
  // Polygon Mainnet
  137: {
    v1RegistryAddress: "0x5C5E2D94b107C7691B08E43169fDe76EAAB6D48b",
  },
  // Arbitrum One Mainnet
  42161: {
    v1RegistryAddress: "0x73AB205af1476Dc22104A6B8b3d4c273B58C6E27",
  },
  // Base Mainnet
  8453: {
    v1RegistryAddress: "0xA78Daa89fE9C1eC66c5cB1c5833bC8C6Cb307918",
  },
  // Fantom Mainnet
  250: {
    v1RegistryAddress: "0xAdcB64860902A29c3e408586C782A2221d595B55",
  },
  // Avalanche Mainnet
  43114: {
    v1RegistryAddress: "0xDF9BF58Aa1A1B73F0e214d79C652a7dd37a6074e",
  },
  // ZKSync Mainnet
  324: {
    v1RegistryAddress: "0xe6CCEe93c97E20644431647B306F48e278aFFdb9",
  },
};
