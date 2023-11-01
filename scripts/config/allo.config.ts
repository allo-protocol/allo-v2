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
    owner: "0x34d82D1ED8B4fB6e6A569d6D086A39f9f734107E",
    treasury: "0x34d82D1ED8B4fB6e6A569d6D086A39f9f734107E",
    percentFee: 0,
    baseFee: 0,
  },
  // Goerli
  5: {
    owner: "0x443dA927D9877C1B7D5E13C092Cb1958D3b90FaE",
    treasury: "0x443dA927D9877C1B7D5E13C092Cb1958D3b90FaE",
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
    owner: "0x791BB7b7e16982BDa029893077EEb4F77A2CD564",
    treasury: "0x791BB7b7e16982BDa029893077EEb4F77A2CD564",
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
    owner: "0xc8c4F1b9980B583E3428F183BA44c65D78C15251",
    treasury: "0xc8c4F1b9980B583E3428F183BA44c65D78C15251",
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
    owner: "0xEfEAB1ea32A5d7c6B1DE6192ee531A2eF51198D9",
    treasury: "0xEfEAB1ea32A5d7c6B1DE6192ee531A2eF51198D9",
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
  // Base Mainnet
  8453: {
    owner: "0x850a5515123f49c298DdF33E581cA01bFF928FEf",
    treasury: "0x850a5515123f49c298DdF33E581cA01bFF928FEf",
    percentFee: 0,
    baseFee: 0,
  },
  // Base Testnet Goerli
  84531: {
    owner: "",
    treasury: "",
    percentFee: 0,
    baseFee: 0,
  },
};
