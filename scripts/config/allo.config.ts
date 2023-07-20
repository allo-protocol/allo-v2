// NOTE: Update this file anytime a new Registry is deployed.

type AlloConfig = {
	registry: string;
	treasury: string;
	feePercentage: number;
	baseFee: number;
	feeSkirtingBountyPercentage: number;
};

type DeployParams = Record<number, AlloConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const alloConfig: DeployParams = {
	// Mainnet
	1: {
		registry: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
		feeSkirtingBountyPercentage: 0,
	},
	// PGN
	424: {
		registry: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
		feeSkirtingBountyPercentage: 0,
	},
	// Optimism
	10: {
		registry: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
		feeSkirtingBountyPercentage: 0,
	},
	// Optimism Testnet
	69: {
		registry: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
		feeSkirtingBountyPercentage: 0,
	},
	// Goerli
	5: {
		registry: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
		feeSkirtingBountyPercentage: 0,
	},
	// Sepolia
	11155111: {
		registry: "0xC7FF8a85f5F3969DbeCb370a31f22B32fd75A8bB",
		treasury: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
		feePercentage: 0,
		baseFee: 0,
		feeSkirtingBountyPercentage: 0,
	},
	// Fantom
	250: {
		registry: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
		feeSkirtingBountyPercentage: 0,
	},
	// Fantom Testnet
	4002: {
		registry: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
		feeSkirtingBountyPercentage: 0,
	},
};
