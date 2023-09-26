// NOTE: Update this file anytime a new allo is deployed.

type AlloConfig = {
	alloImplementation: string;
	alloProxy: string,
	treasury: string;
	percentFee: number;
	baseFee: number;
};

type DeployParams = Record<number, AlloConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const alloConfig: DeployParams = {
  // Mainnet
  1: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Goerli
  5: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Sepolia
  11155111: {
    alloImplementation: "0x27efa1c90e097c980c669ab1a6e326ad4164f1cb",
    alloProxy: "0xfF65C1D4432D23C45b0730DaeCd03b6B92cd074a",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // PGN
  424: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // PGN Sepolia
  58008: {
    alloImplementation: "0x27efa1c90e097c980c669ab1a6e326ad4164f1cb",
    alloProxy: "0xfF65C1D4432D23C45b0730DaeCd03b6B92cd074a",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Optimism
  10: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Optimism Goerli
  420: {
    alloImplementation: "0x27efa1c90e097c980c669ab1a6e326ad4164f1cb",
    alloProxy: "0xfF65C1D4432D23C45b0730DaeCd03b6B92cd074a",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Fantom
  250: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Fantom Testnet
  4002: {
    alloImplementation: "0xdc84440e5b93a6915fa32c1bd75d49e4137e2dcf",
    alloProxy: "0xb8008FdCf35f8A3D59126337Bf68D32DdC0Eb99E",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Celo Mainnet
  42220: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Celo Testnet Alfajores
  44787: {
    alloImplementation: "",
    alloProxy: "0xDc84440E5b93a6915fa32C1BD75d49E4137E2Dcf",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // ZkSync Era Mainnet
  324: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // ZkSync Era Testnet
  280: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Polygon Mainnet
  137: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Mumbai
  80001: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Arbitrum One
  42161: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Arbitrum Goerli
  421613: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Avalanche Mainnet
  43114: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
  // Avalanche Fuji Testnet
  43113: {
    alloImplementation: "",
    alloProxy: "",
    treasury: "0xEED057c794A5cCcEbd96c5B441a31e1889b85eF7",
    percentFee: 0,
    baseFee: 0,
  },
};
