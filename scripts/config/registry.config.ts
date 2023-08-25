// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  registryImplementation: string;
  registryProxy: string;
  owner: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const registryConfig: DeployParams = {
  // Mainnet
  1: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0x0",
  },
  // Goerli
  5: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // Sepolia
  11155111: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // PGN
  424: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0x0",
  },
  // PGN Sepolia
  58008: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // Optimism
  10: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0x0",
  },
  // Optimism Goerli
  420: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // Fantom
  250: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0x0",
  },
  // Fantom Testnet
  4002: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // Celo Mainnet
  42220: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0x0",
  },
  // Celo Testnet Alfajores
  44787: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
};
