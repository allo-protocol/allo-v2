// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  owner: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registry on each network.
export const registryConfig: DeployParams = {
  // Mainnet
  1: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // Goerli
  5: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // Sepolia
  11155111: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // PGN
  424: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // PGN Sepolia
  58008: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // Optimism
  10: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // Optimism Goerli
  420: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // Fantom
  250: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // Fantom Testnet
  4002: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // Celo Mainnet
  42220: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // Celo Testnet Alfajores
  44787: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // zkSync-testnet
  280: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // zkSync-mainnet
  324: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
};
