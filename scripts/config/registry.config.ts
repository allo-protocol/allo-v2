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
    registryImplementation: "0xd34db3b8b10faa6bfc421e919fab0272d542c1d6",
    registryProxy: "0xBC23124Ed2655A1579291f7ADDE581fF18327D41",
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
  // Sepolia
  11155111: {
    registryImplementation: "",
    registryProxy: "",
    owner: "",
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
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "",
  },
  // zkSync-mainnet
  324: {
    registryImplementation: "0x0",
    registryProxy: "0x0",
    owner: "",
  },
};
