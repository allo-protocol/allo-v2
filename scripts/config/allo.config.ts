// NOTE: Update this file anytime a new allo is deployed.

type AlloConfig = {
  treasury: string;
  percentFee: number;
  baseFee: number;
};

type DeployParams = Record<number, AlloConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const alloConfig: DeployParams = {
  // Mainnet
  1: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Goerli
  5: {
    treasury: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
    percentFee: 0,
    baseFee: 0,
  },
  // Sepolia
  11155111: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // PGN
  424: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // PGN Sepolia
  58008: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Optimism
  10: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Optimism Goerli
  420: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Fantom
  250: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Fantom Testnet
  4002: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Celo Mainnet
  42220: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Celo Testnet Alfajores
  44787: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // ZkSync Era Mainnet
  324: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // ZkSync Era Testnet
  280: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Polygon Mainnet
  137: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Mumbai
  80001: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Arbitrum One
  42161: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Arbitrum Goerli
  421613: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Avalanche Mainnet
  43114: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
  // Avalanche Fuji Testnet
  43113: {
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
};
