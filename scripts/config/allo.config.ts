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
	// Sepolia
	11155111: {
		allo: "",
		treasury: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
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
	// PGN Sepolia
	58008: {
		allo: "0x0",
		treasury: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
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
		treasury: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
		feePercentage: 0,
		baseFee: 0,
	},
	// Goerli
	5: {
		allo: "0x0",
		treasury: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
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
		treasury: "0x62BfD2d4aDfB40ee6aBe81E09DD1959Ce8c76b3F",
		feePercentage: 0,
		baseFee: 0,
	},
};
