// NOTE: Update this file anytime a new allo is deployed.

type AlloConfig = {
  owner: string;
  treasury: string;
  percentFee: number;
  baseFee: number;
};

type DeployParams = Record<number, AlloConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const alloConfig: DeployParams = {
  // Mainnet
  1: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Goerli
  5: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Sepolia
  11155111: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // PGN
  424: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // PGN Sepolia
  58008: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Optimism
  10: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Optimism Goerli
  420: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Celo Mainnet
  42220: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Celo Testnet Alfajores
  44787: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Polygon Mainnet
  137: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Mumbai
  80001: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Arbitrum One
  42161: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Arbitrum Goerli
  421613: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
};
