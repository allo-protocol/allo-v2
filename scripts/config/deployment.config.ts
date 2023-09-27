import { Addressable } from "ethers";

type DeployerConfig = {
  [key: number]: { address: string | Addressable };
};

export const deployerContractAddress: DeployerConfig = {
  // Mainnet
  1: {
    address: "",
  },
  // Goerli
  5: {
    address: "",
  },
  // Sepolia
  11155111: {
    address: "0xF39FF686369C8bA9D9c3790398F79700b2c3fbFA",
  },
  // PGN
  424: {
    address: "",
  },
  // PGN Sepolia
  58008: {
    address: "",
  },
  // Optimism
  10: {
    address: "",
  },
  // Optimism Goerli
  420: {
    address: "",
  },
  // Fantom
  250: {
    address: "",
  },
  // Fantom Testnet
  4002: {
    address: "",
  },
  // Celo Mainnet
  42220: {
    address: "",
  },
  // Celo Alfajores
  44787: {
    address: "",
  },
  // ZkSync Era Mainnet
  324: {
    address: "",
  },
  // ZkSync Era Testnet
  280: {
    address: "",
  }
};
