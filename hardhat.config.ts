import * as dotenv from "dotenv";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-solhint";
import "@nomiclabs/hardhat-waffle";
import "@nomicfoundation/hardhat-foundry";
import "@openzeppelin/hardhat-upgrades";
import "@primitivefi/hardhat-dodoc";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import "solidity-coverage";
import "hardhat-preprocessor";
import fs from "fs";

dotenv.config();

const chainIds = {
  // local network
  localhost: 31337,

  // testnet
  goerli: 5,
  sepolia: 11155111,
  "optimism-goerli": 420,
  "fantom-testnet": 4002,
  "pgn-sepolia": 58008,
  "celo-testnet": 44787,

  // mainnet
  mainnet: 1,
  "optimism-mainnet": 10,
  "pgn-mainnet": 424,
  "fantom-mainnet": 250,
  "celo-mainnet": 42220,
};

let deployPrivateKey = process.env.DEPLOYER_PRIVATE_KEY as string;
if (!deployPrivateKey) {
  // default first account deterministically created by local nodes like `npx hardhat node` or `anvil`
  throw "No deployer private key set in .env";
}

const infuraIdKey = process.env.INFURA_RPC_ID as string;

/**
 * Reads the remappings.txt file and returns an array of arrays.
 * @returns {string[][]}
 */
function getRemappings() {
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
  url?: string
): NetworkUserConfig {
  if (!url) {
    url = `https://${network}.infura.io/v3/${infuraIdKey}`;
  }
  return {
    accounts: [deployPrivateKey],
    chainId: chainIds[network],
    allowUnlimitedContractSize: true,
    url,
    gasPrice: 20000000000,
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
  url?: string
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

const dodoc = {
  outputDir: "./generated-docs/contracts",
  include: ["contracts"],
  exclude: ["lib", "test"],
};

const config: HardhatUserConfig = {
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
    "optimism-mainnet": createMainnetConfig("optimism-mainnet"),
    "fantom-mainnet": createMainnetConfig(
      "fantom-mainnet",
      "https://rpc.ftm.tools"
    ),
    "pgn-mainnet": {
      accounts: [deployPrivateKey],
      chainId: chainIds["pgn-mainnet"],
      url: "https://rpc.publicgoods.network",
      gasPrice: 20000000000,
    },
    "celo-mainnet": {
      accounts: [deployPrivateKey],
      chainId: chainIds["celo-mainnet"],
      url: "https://forno.celo.org",
      gasPrice: 20000000000,
    },

    // Test Networks
    goerli: createTestnetConfig("goerli"),
    sepolia: createTestnetConfig(
      "sepolia",
      "https://eth-sepolia.public.blastapi.io"
    ),
    "fantom-testnet": createTestnetConfig(
      "fantom-testnet",
      "https://rpc.testnet.fantom.network/"
    ),
    "optimism-goerli": {
      accounts: [deployPrivateKey],
      chainId: chainIds["optimism-goerli"],
      url: "https://optimism-goerli.publicnode.com",
      gasPrice: 20000000000,
    },
    "pgn-sepolia": {
      accounts: [deployPrivateKey],
      chainId: chainIds["pgn-sepolia"],
      url: "https://sepolia.publicgoods.network",
      gasPrice: 20000000000,
    },
    "celo-testnet": {
      accounts: [deployPrivateKey],
      chainId: chainIds["celo-testnet"],
      url: "https://alfajores-forno.celo-testnet.org",
      gasPrice: 20000000000,
    },

    // Local Networks
    localhost: createTestnetConfig("localhost", "http://localhost:8545"),
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
          apiURL: "https://celoscan.io/api",
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
    ],
  },
  abiExporter: abiExporter,
  dodoc: dodoc,
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
