// NOTE: Update this file anytime a new allo is deployed.

type AlloConfig = {
	allo: string;
	treasury: string;
	feePercentage: number;
	baseFee: number;
};

type DeployParams = Record<number, AlloConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const alloConfig: DeployParams = {
	// Mainnet
	1: {
		allo: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
	// PGN
	424: {
		allo: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
	// Optimism
	10: {
		allo: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
	// Optimism Testnet
	69: {
		allo: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
	// Goerli
	5: {
		allo: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
	// Sepolia
	11155111: {
		allo: "0xC7FF8a85f5F3969DbeCb370a31f22B32fd75A8bB",
		treasury: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
		feePercentage: 0,
		baseFee: 0,
	},
	// Fantom
	250: {
		allo: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
	// Fantom Testnet
	4002: {
		allo: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
};
