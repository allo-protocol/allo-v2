import { Addressable } from "ethers";

type DeployerConfig = {
  [key: number]: { address: string | Addressable; testnet?: boolean };
};

export const deployerContractAddress: DeployerConfig = {
  // Mainnet
  1: {
    address: "",
    testnet: false,
  },
  // Goerli
  5: {
    address: "",
    testnet: true,
  },
  // Sepolia
  11155111: {
    address: "",
    testnet: true,
  },
  // PGN
  424: {
    address: "",
    testnet: false,
  },
  // PGN Sepolia
  58008: {
    address: "",
    testnet: true,
  },
  // Optimism
  10: {
    address: "",
    testnet: false,
  },
  // Optimism Goerli
  420: {
    address: "",
    testnet: true,
  },
  // Fantom
  250: {
    address: "",
    testnet: false,
  },
  // Fantom Testnet
  4002: {
    address: "",
    testnet: true,
  },
  // Celo Mainnet
  42220: {
    address: "",
    testnet: false,
  },
  // Celo Alfajores
  44787: {
    address: "",
    testnet: true,
  },
  // ZkSync Era Mainnet
  324: {
    address: "",
    testnet: false,
  },
  // ZkSync Era Testnet
  280: {
    address: "",
    testnet: true,
  },
  // Polygon Mainnet
  137: {
    address: "",
    testnet: false,
  },
  // Polygon Mumbai Testnet
  80001: {
    address: "",
    testnet: true,
  },
  // Arbitrum One Mainnet
  42161: {
    address: "",
    testnet: false,
  },
  // Arbitrum Goerli
  421613: {
    address: "0x48ec14DF06dA7322f0D63541BC1eC5B2785D3FD2", // Deployed on 10/24/23:1530 EST
  },
  // Base Mainnet
  8453: {
    address: "",
    testnet: false,
  },
  // Base Testnet Goerli
  84531: {
    address: "",
    testnet: true,
  },
};
