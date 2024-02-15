import * as dotenv from "dotenv";

import "@nomicfoundation/hardhat-foundry";
import "@nomicfoundation/hardhat-verify";
import "@nomiclabs/hardhat-solhint";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import fs from "fs";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import "hardhat-preprocessor";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import "solidity-coverage";

dotenv.config();

const chainIds = {
  // local network
  localhost: 31337,

  // testnet
  goerli: 5,
  sepolia: 11155111,
  "optimism-goerli": 420,
  "optimism-sepolia": 11155420,
  "fantom-testnet": 4002,
  "pgn-sepolia": 58008,
  "celo-testnet": 44787,
  "arbitrum-goerli": 421613,
  "arbitrum-sepolia": 421614,
  "base-testnet": 84531,
  mumbai: 80001,

  // mainnet
  mainnet: 1,
  "optimism-mainnet": 10,
  "pgn-mainnet": 424,
  "fantom-mainnet": 250,
  "celo-mainnet": 42220,
  "arbitrum-mainnet": 42161,
  base: 8453,
  polygon: 137,
};

let deployPrivateKey = process.env.DEPLOYER_PRIVATE_KEY as string;
if (!deployPrivateKey) {
  // default first account deterministically created by local nodes like `npx hardhat node` or `anvil`
  throw "No deployer private key set in .env";
}

const infuraIdKey = process.env.INFURA_RPC_ID as string;
const alchemyIdKey = process.env.ALCHEMY_RPC_ID as string;
const DEFENDER_TEAM_API_KEY = process.env.DEFENDER_TEAM_API_KEY as string;
const DEFENDER_TEAM_API_SECRET_KEY = process.env
  .DEFENDER_TEAM_API_SECRET_KEY as string;

/**
 * Reads the remappings.txt file and returns an array of arrays.
 * @returns {string[][]}
 */
function getRemappings(): string[][] {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));
}

/**
 * Generates hardhat network configuration the test networks.
 * @param network
 * @param url (optional)
 * @returns {NetworkUserConfig}
 */
function createTestnetConfig(
  network: keyof typeof chainIds,
  url?: string,
): NetworkUserConfig {
  if (!url) {
    url = `https://${network}.infura.io/v3/${infuraIdKey}`;
  }
  return {
    accounts: [deployPrivateKey],
    chainId: chainIds[network],
    allowUnlimitedContractSize: true,
    url,
    gasPrice: 30000000000,
  };
}

/**
 * Generates hardhat network configuration the mainnet networks.
 * @param network
 * @param url (optional)
 * @returns {NetworkUserConfig}
 */
function createMainnetConfig(
  network: keyof typeof chainIds,
  url?: string,
): NetworkUserConfig {
  if (!url) {
    url = `https://${network}.infura.io/v3/${infuraIdKey}`;
  }
  return {
    accounts: [deployPrivateKey],
    chainId: chainIds[network],
    url,
  };
}

const abiExporter = [
  {
    path: "./abis/pretty",
    flat: true,
    clear: true,
    format: "fullName",
  },
  {
    path: "./abis/ugly",
    flat: true,
    clear: true,
  },
];

/**
 * Generates hardhat network configuration
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  defender: {
    apiKey: DEFENDER_TEAM_API_KEY,
    apiSecret: DEFENDER_TEAM_API_SECRET_KEY,
  },
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 400,
      },
    },
    // @ts-ignore
  },
  networks: {
    // Main Networks
    mainnet: createMainnetConfig("mainnet"),
    "optimism-mainnet": {
      ...createMainnetConfig("optimism-mainnet"),
      url: `https://opt-mainnet.g.alchemy.com/v2/${alchemyIdKey}`,
      // gasPrice: 35000000000,
    },
    "arbitrum-mainnet": createMainnetConfig(
      "arbitrum-mainnet",
      `https://arb-mainnet.g.alchemy.com/v2/${alchemyIdKey}`,
    ),
    "fantom-mainnet": createMainnetConfig(
      "fantom-mainnet",
      "https://rpc.ftm.tools",
    ),
    "pgn-mainnet": {
      ...createMainnetConfig("pgn-mainnet"),
      url: "https://rpc.publicgoods.network",
      gasPrice: 20000000000,
    },
    "celo-mainnet": {
      ...createMainnetConfig("celo-mainnet"),
      url: "https://forno.celo.org",
    },
    base: {
      ...createMainnetConfig("base"),
      url: `https://base-mainnet.g.alchemy.com/v2/${alchemyIdKey}`,
    },
    polygon: {
      ...createMainnetConfig("polygon"),
      url: `https://polygon-mainnet.g.alchemy.com/v2/${alchemyIdKey}`,
      gasPrice: 300000000000,
    },

    // Test Networks
    goerli: createTestnetConfig(
      "goerli",
      `https://eth-goerli.g.alchemy.com/v2/${alchemyIdKey}`,
    ),
    sepolia: createTestnetConfig(
      "sepolia",
      `https://eth-sepolia.g.alchemy.com/v2/${alchemyIdKey}`,
    ),
    "arbitrum-goerli": createTestnetConfig(
      "arbitrum-goerli",
      `https://arb-goerli.g.alchemy.com/v2/${alchemyIdKey}`,
    ),
    "arbitrum-sepolia": createTestnetConfig(
      "arbitrum-sepolia",
      `https://arb-sepolia.g.alchemy.com/v2/${alchemyIdKey}`,
    ),
    ftmTestnet: createTestnetConfig(
      "fantom-testnet",
      "https://rpc.testnet.fantom.network/",
    ),
    "optimism-goerli": {
      ...createTestnetConfig("optimism-goerli"),
      url: "https://optimism-goerli.publicnode.com",
      gasPrice: 20000000000,
    },
    "pgn-sepolia": {
      ...createTestnetConfig("pgn-sepolia"),
      url: "https://sepolia.publicgoods.network",
      gasPrice: 20000000000,
    },
    "celo-testnet": {
      ...createTestnetConfig("celo-testnet"),
      url: "https://alfajores-forno.celo-testnet.org",
      gasPrice: 20000000000,
    },
    "base-testnet": {
      ...createTestnetConfig("base-testnet"),
      url: `https://base-goerli.g.alchemy.com/v2/${alchemyIdKey}`,
      gasPrice: 20000000000,
    },
    "optimism-sepolia": {
      ...createTestnetConfig("optimism-sepolia"),
      url: `https://sepolia.optimism.io`,
    },
    mumbai: {
      ...createTestnetConfig("mumbai"),
      url: `https://polygon-mumbai.g.alchemy.com/v2/${alchemyIdKey}`,
      gasPrice: 20000000000,
    },

    // Local Networks
    localhost: createTestnetConfig("localhost", "http://localhost:8545"),
    hardhat: {
      // forking: {
      //   url: process.env.MAINNET,
      //   blockNumber: 33317730,
      // },
      mining: {
        auto: false,
        interval: 1000,
      },
    },
  },
  gasReporter: {
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    excludeContracts: ["contracts/mocks", "contracts/dummy"],
  },
  etherscan: {
    apiKey: {
      // @ts-ignore
      mainnet: process.env.ETHERSCAN_API_KEY,
      // @ts-ignore
      goerli: process.env.ETHERSCAN_API_KEY,
      // @ts-ignore
      sepolia: process.env.ETHERSCAN_API_KEY,
      // @ts-ignore
      optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY,
      // @ts-ignore
      optimisticGoerli: process.env.OPTIMISTIC_ETHERSCAN_API_KEY,
      // @ts-ignore
      ftmTestnet: process.env.FTMSCAN_API_KEY,
      // @ts-ignore
      opera: process.env.FTMSCAN_API_KEY,
      // @ts-ignore
      "pgn-mainnet": process.env.PGNSCAN_API_KEY,
      // @ts-ignore
      "pgn-sepolia": process.env.PGNSCAN_API_KEY,
      // @ts-ignore
      "celo-mainnet": process.env.CELOSCAN_API_KEY,
      // @ts-ignore
      "celo-testnet": process.env.CELOSCAN_API_KEY,
      // @ts-ignore
      base: process.env.BASESCAN_API_KEY,
      // @ts-ignore
      "base-testnet": process.env.BASESCAN_API_KEY,
      // @ts-ignore
      polygon: process.env.POLYGONSCAN_API_KEY,
      // @ts-ignore
      mumbai: process.env.POLYGONSCAN_API_KEY,
      // @ts-ignore
      "arbitrum-mainnet": process.env.ARBITRUMSCAN_API_KEY,
      // @ts-ignore
      "arbitrum-sepolia": process.env.ARBITRUMSCAN_API_KEY,
      // @ts-ignore
      "optimism-sepolia": process.env.OPTIMISTIC_ETHERSCAN_API_KEY,
    },
    customChains: [
      {
        network: "pgn-mainnet",
        chainId: chainIds["pgn-mainnet"],
        urls: {
          apiURL: "https://explorer.publicgoods.network/api",
          browserURL: "https://explorer.publicgoods.network",
        },
      },
      {
        network: "pgn-sepolia",
        chainId: chainIds["pgn-sepolia"],
        urls: {
          apiURL: "https://explorer.sepolia.publicgoods.network/api",
          browserURL: "https://explorer.sepolia.publicgoods.network",
        },
      },
      {
        network: "celo-mainnet",
        chainId: chainIds["celo-mainnet"],
        urls: {
          apiURL: "https://api.celoscan.io/api",
          browserURL: "https://celoscan.io",
        },
      },
      {
        network: "celo-testnet",
        chainId: chainIds["celo-testnet"],
        urls: {
          apiURL: "https://api-alfajores.celoscan.io/api",
          browserURL: "https://alfajores.celoscan.io",
        },
      },
      {
        network: "base",
        chainId: chainIds["base"],
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org/",
        },
      },
      {
        network: "base-testnet",
        chainId: chainIds["base-testnet"],
        urls: {
          apiURL: "https://api-goerli.basescan.org/api",
          browserURL: "https://goerli.basescan.org/",
        },
      },
      {
        network: "polygon",
        chainId: chainIds["polygon"],
        urls: {
          apiURL: "https://api.polygonscan.com/api",
          browserURL: "https://polygonscan.com",
        },
      },
      {
        network: "mumbai",
        chainId: chainIds["mumbai"],
        urls: {
          apiURL: "https://api-mumbai.polygonscan.com/api",
          browserURL: "https://mumbai.polygonscan.com/",
        },
      },
      {
        network: "arbitrum-mainnet",
        chainId: chainIds["arbitrum-mainnet"],
        urls: {
          apiURL: "https://api.arbiscan.io/api",
          browserURL: "https://arbiscan.io",
        },
      },
      {
        network: "arbitrum-sepolia",
        chainId: chainIds["arbitrum-sepolia"],
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://arbiscan.io",
        },
      },
      {
        network: "optimism-sepolia",
        chainId: chainIds["optimism-sepolia"],
        urls: {
          apiURL: "https://api-sepolia-optimistic.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io",
        },
      },
    ],
  },
  abiExporter: abiExporter,
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          for (const [from, to] of getRemappings()) {
            if (line.includes(from)) {
              line = line.replace(from, to);
              break;
            }
          }
        }
        return line;
      },
    }),
  },
  paths: {
    sources: "./contracts",
    cache: "./cache_hardhat",
  },
};

export default config;
