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
    registry: "",
    owner: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
  },
  // Sepolia
  11155111: {
    registry: "0x0e6c54D4cC786127F34B0fF1B569eC3Db89F8824",
    owner: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
  },
  // PGN
  424: {
    registry: "",
    owner: "",
  },
  // PGN Sepolia
  58008: {
    registry: "",
    owner: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
  },
  // Optimism
  10: {
    registry: "",
    owner: "",
  },
  // Optimism Testnet
  69: {
    registry: "",
    owner: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
  },
  // Fantom
  250: {
    registry: "",
    owner: "",
  },
  // Fantom Testnet
  4002: {
    registry: "",
    owner: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
  },
};
