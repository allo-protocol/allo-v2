// NOTE: Update this file anytime a new allo is deployed.

type AlloConfig = {
	allo: string;
	proxyAddress: string,
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
		proxyAddress: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
	// Goerli
	5: {
		allo: "0x45F5506b0014cbdc9652854B65eed90E56aB7dA9",
		proxyAddress: "0x97122901b6346a625294d446f5d0b7bc00a3b0f2",
		treasury: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
		feePercentage: 0,
		baseFee: 0,
	},
	// Sepolia
	11155111: {
		allo: "0x45F5506b0014cbdc9652854B65eed90E56aB7dA9",
		proxyAddress: "0x97122901b6346a625294d446f5d0b7bc00a3b0f2",
		treasury: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
		feePercentage: 0,
		baseFee: 0,
	},
	// PGN
	424: {
		allo: "0x0",
		proxyAddress: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
	// PGN Sepolia
	58008: {
		allo: "0x45F5506b0014cbdc9652854B65eed90E56aB7dA9",
		proxyAddress: "0x97122901b6346a625294d446f5d0b7bc00a3b0f2",
		treasury: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
		feePercentage: 0,
		baseFee: 0,
	},
	// Optimism
	10: {
		allo: "0x0",
		proxyAddress: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
	// Optimism Goerli
	420: {
		allo: "0x45F5506b0014cbdc9652854B65eed90E56aB7dA9",
		proxyAddress: "0x97122901b6346a625294d446f5d0b7bc00a3b0f2",
		treasury: "0x24aE808BAe513fA698d4C188b88538d9C909f83E",
		feePercentage: 0,
		baseFee: 0,
	},
	// Fantom
	250: {
		allo: "0x0",
		proxyAddress: "0x0",
		treasury: "0x0",
		feePercentage: 0,
		baseFee: 0,
	},
};
