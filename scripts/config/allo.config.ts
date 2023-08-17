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
    alloImplementation: "0x0",
    alloProxy: "0x0",
    treasury: "0x0",
    percentFee: 0,
    baseFee: 0,
  },
  // Goerli
  5: {
    alloImplementation: "0x8dde1922d5f772890f169714faceef9551791caf",
    alloProxy: "0x79536CC062EE8FAFA7A19a5fa07783BD7F792206",
    treasury: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
    percentFee: 0,
    baseFee: 0,
  },
  // Sepolia
  11155111: {
    alloImplementation: "0x8dde1922d5f772890f169714faceef9551791caf",
    alloProxy: "0x79536CC062EE8FAFA7A19a5fa07783BD7F792206",
    treasury: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
    percentFee: 0,
    baseFee: 0,
  },
  // PGN
  424: {
    alloImplementation: "0x0",
    alloProxy: "0x0",
    treasury: "0x0",
    percentFee: 0,
    baseFee: 0,
  },
  // PGN Sepolia
  58008: {
    alloImplementation: "0x8dde1922d5f772890f169714faceef9551791caf",
    alloProxy: "0x79536CC062EE8FAFA7A19a5fa07783BD7F792206",
    treasury: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
    percentFee: 0,
    baseFee: 0,
  },
  // Optimism
  10: {
    alloImplementation: "0x0",
    alloProxy: "0x0",
    treasury: "0x0",
    percentFee: 0,
    baseFee: 0,
  },
  // Optimism Goerli
  420: {
    alloImplementation: "0x8dde1922d5f772890f169714faceef9551791caf",
    alloProxy: "0x79536CC062EE8FAFA7A19a5fa07783BD7F792206",
    treasury: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
    percentFee: 0,
    baseFee: 0,
  },
  // Fantom
  250: {
    alloImplementation: "0x0",
    alloProxy: "0x0",
    treasury: "0x0",
    percentFee: 0,
    baseFee: 0,
  },
  // Fantom Testnet
  4002: {
    alloImplementation: "0x0",
    alloProxy: "0x0",
    treasury: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
    percentFee: 0,
    baseFee: 0,
  },
  // Celo Mainnet
  42220: {
    alloImplementation: "0x0",
    alloProxy: "0x0",
    treasury: "0X0",
    percentFee: 0,
    baseFee: 0,
  },
  // Celo Testnet Alfajores
  44787: {
    alloImplementation: "0x8dde1922d5f772890f169714faceef9551791caf",
    alloProxy: "0x79536CC062EE8FAFA7A19a5fa07783BD7F792206",
    treasury: "0xBa0BBfB320486119f97Ea9C4671dE5e45441B2b7",
    percentFee: 0,
    baseFee: 0,
  },
};
