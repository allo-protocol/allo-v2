type CommonConfig = {
  proxyAdminOwner?: string,
  permit2Address: string,
};

type DeployParams = Record<number, CommonConfig>;

export const commonConfig: DeployParams = {
  // Mainnet
  1: {
    proxyAdminOwner: "0x34d82D1ED8B4fB6e6A569d6D086A39f9f734107E",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Goerli
  5: {
    proxyAdminOwner: "0x91AE7C39D43fbEA2E564E5128ac0469200e50da1",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Sepolia
  11155111: {
    proxyAdminOwner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // PGN
  424: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // PGN Sepolia
  58008: {
    proxyAdminOwner: "",
    permit2Address: "",
  },
  // Optimism
  10: {
    proxyAdminOwner: "0x791BB7b7e16982BDa029893077EEb4F77A2CD564",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Optimism Goerli
  420: {
    proxyAdminOwner: "0x2709Ec5Fbe9Ed9b985Bd9F2C9587E09A8Fa8af33",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Celo Mainnet
  42220: {
    proxyAdminOwner: "0x8AA4514A31A69e3cba946F8f29899Bc189b01f2C",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Celo Testnet Alfajores
  44787: {
    proxyAdminOwner: "0x0C08E6cA059907769a42F95274f0b2b9D96fA4D2",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Polygon Mainnet
  137: {
    proxyAdminOwner: "0xc8c4F1b9980B583E3428F183BA44c65D78C15251",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Mumbai
  80001: {
    proxyAdminOwner: "0x00F06079089ca6F56D64682b8F3D4C6b067b612C",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Arbitrum One
  42161: {
    proxyAdminOwner: "0xEfEAB1ea32A5d7c6B1DE6192ee531A2eF51198D9",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Arbitrum Sepolia
  421614: {
    proxyAdminOwner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
    permit2Address: "0x000000000022d473030f116ddee9f6b43ac78ba3",
  },
  // Base Mainnet
  8453: {
    proxyAdminOwner: "0x850a5515123f49c298DdF33E581cA01bFF928FEf",
    permit2Address: "0x000000000022D473030F116dDEE9F6B43aC78BA3",
  },
  // Base Testnet Goerli
  84531: {
    proxyAdminOwner: "0xB145b7742A5a082C4f334981247E148dB9dF0cb3",
    permit2Address: "0x000000000022D473030F116dDEE9F6B43aC78BA3",
  },
  // Optimism Sepolia
  11155420: {
    proxyAdminOwner: "0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C",
    permit2Address: "0x000000000022D473030F116dDEE9F6B43aC78BA3",
  },
};
