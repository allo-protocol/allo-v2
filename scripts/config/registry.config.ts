// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  owner: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registry on each network.
export const registryConfig: DeployParams = {
  // Mainnet
  1: {
    owner: "0x34d82D1ED8B4fB6e6A569d6D086A39f9f734107E",
  },
  // Goerli
  5: {
    owner: "0x91AE7C39D43fbEA2E564E5128ac0469200e50da1",
  },
  // Sepolia
  11155111: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Optimism
  10: {
    owner: "0x791BB7b7e16982BDa029893077EEb4F77A2CD564",
  },
  // Optimism Goerli
  420: {
    owner: "0x2709Ec5Fbe9Ed9b985Bd9F2C9587E09A8Fa8af33",
  },
  // Celo Mainnet
  42220: {
    owner: "0x8AA4514A31A69e3cba946F8f29899Bc189b01f2C",
  },
  // Celo Testnet Alfajores
  44787: {
    owner: "0x0C08E6cA059907769a42F95274f0b2b9D96fA4D2",
  },
  // Polygon Mainnet
  137: {
    owner: "0xc8c4F1b9980B583E3428F183BA44c65D78C15251",
  },
  // Polygon Mumbai Testnet
  80001: {
    owner: "0x00F06079089ca6F56D64682b8F3D4C6b067b612C",
  },
  // Arbitrum One Mainnet
  42161: {
    owner: "0xEfEAB1ea32A5d7c6B1DE6192ee531A2eF51198D9",
  },
  // Arbitrum Sepolia
  421614: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Base Mainnet
  8453: {
    owner: "0x850a5515123f49c298DdF33E581cA01bFF928FEf",
  },
  // Base Testnet Goerli
  84531: {
    owner: "0xB145b7742A5a082C4f334981247E148dB9dF0cb3",
  },
  // Optimism Sepolia
  11155420: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Fuji
  43113: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Avalanche
  43114: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Scroll
  534352: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Fantom
  250: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Fantom Testnet
  4002: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // ZkSync Mainnet
  324: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // ZkSync Tesnet
  300: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Filecoin Mainnet
  314: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Filecoin Calibration Testnet
  314159: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Sei Devnet
  713715: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  1329: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Lukso Testnet
  4201: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Lukso Mainnet
  42: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Metis andromeda
  1088: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
  // Gnosis
  100: {
    owner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
  },
};
