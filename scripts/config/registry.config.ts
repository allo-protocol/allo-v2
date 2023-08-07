// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  registry: string;
  owner: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const registryConfig: DeployParams = {
  // Mainnet
  1: {
    registry: "",
    owner: "",
  },
  // Goerli
  5: {
    registry: "0xAEc621EC8D9dE4B524f4864791171045d6BBBe27",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // Sepolia
  11155111: {
    registry: "0xAEc621EC8D9dE4B524f4864791171045d6BBBe27",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // PGN
  424: {
    registry: "",
    owner: "",
  },
  // PGN Sepolia
  58008: {
    registry: "0xAEc621EC8D9dE4B524f4864791171045d6BBBe27",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // Optimism
  10: {
    registry: "",
    owner: "",
  },
  // Optimism Goerli
  420: {
    registry: "0xAEc621EC8D9dE4B524f4864791171045d6BBBe27",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // Fantom
  250: {
    registry: "",
    owner: "",
  },
  // Fantom Testnet
  4002: {
    registry: "",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
  // Celo Mainnet
  42220: {
    registry: "",
    owner: "",
  },
  // Celo Testnet Alfajores
  44787: {
    registry: "0xAEc621EC8D9dE4B524f4864791171045d6BBBe27",
    owner: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
  },
};
