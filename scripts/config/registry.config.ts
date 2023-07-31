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
    registry: "0xe571ec2C7b94dE72Bc01937a251E48780DEF882A",
    owner: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
  },
  // Sepolia
  11155111: {
    registry: "0xe571ec2C7b94dE72Bc01937a251E48780DEF882A",
    owner: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
  },
  // PGN
  424: {
    registry: "",
    owner: "",
  },
  // PGN Sepolia
  58008: {
    registry: "0xe571ec2C7b94dE72Bc01937a251E48780DEF882A",
    owner: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
  },
  // Optimism
  10: {
    registry: "",
    owner: "",
  },
  // Optimism Goerli
  420: {
    registry: "0xe571ec2C7b94dE72Bc01937a251E48780DEF882A",
    owner: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
  },
  // Fantom
  250: {
    registry: "",
    owner: "",
  },
  // Fantom Testnet
  4002: {
    registry: "",
    owner: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
  },
};
