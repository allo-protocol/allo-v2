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
    owner: "",
  },
  // Goerli
  5: {
    registryImplementation: "0x29F37376391738Cb030e4B3F529A52070D6C87D0",
    registryProxy: "0xC81746A4Af93cD4c76C3225b1DA48a927f8bcbbA",
    owner: "0x445202a3CB9f41Defdb8A7804035195467471ECA",
  },
  // Sepolia
  11155111: {
    registryImplementation: "0x29F37376391738Cb030e4B3F529A52070D6C87D0",
    registryProxy: "0xC81746A4Af93cD4c76C3225b1DA48a927f8bcbbA",
    owner: "0x445202a3CB9f41Defdb8A7804035195467471ECA",
  },
  // PGN
  424: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "",
  },
  // PGN Sepolia
  58008: {
    registryImplementation: "",
    registryProxy: "",
    owner: "",
  },
  // Optimism
  10: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "",
  },
  // Optimism Goerli
  420: {
    registryImplementation: "",
    registryProxy: "",
    owner: "",
  },
  // Fantom
  250: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "",
  },
  // Fantom Testnet
  4002: {
    registryImplementation: "0xa850b156d256ba38c56e62c84421218b27b82031",
    registryProxy: "0xfF65C1D4432D23C45b0730DaeCd03b6B92cd074a",
    owner: "",
  },
  // Celo Mainnet
  42220: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "",
  },
  // Celo Testnet Alfajores
  44787: {
    registryImplementation: "",
    registryProxy: "",
    owner: "",
  },
  // zkSync-testnet
  280: {
    registryImplementation: "0x219724e4289EE992B2d265D926EDADBa860275De",
    registryProxy: "0xAaFB3c4ccBDd23b6393B79A2EC2Cb99Fafa365C9",
    owner: "0x445202a3CB9f41Defdb8A7804035195467471ECA",
  },
  // zkSync-mainnet
  324: {
    registryImplementation: "",
    registryProxy: "",
    owner: "",
  },
};
