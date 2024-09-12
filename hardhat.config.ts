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
import "@xyrusworx/hardhat-solidity-json";
import "solidity-coverage"; // npx hardhat solidity-json

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
  "celo-testnet": 44787,
  "arbitrum-goerli": 421613,
  "arbitrum-sepolia": 421614,
  "base-testnet": 84531,
  mumbai: 80001,
  "filecoin-calibration": 314159,
  fuji: 43113,
  "sei-devnet": 713715,
  "sei-mainnet": 1329,
  "lukso-testnet": 4201,

  // mainnet
  mainnet: 1,
  "optimism-mainnet": 10,
  "fantom-mainnet": 250,
  "celo-mainnet": 42220,
  "arbitrum-mainnet": 42161,
  base: 8453,
  polygon: 137,
  "filecoin-mainnet": 314,
  avalanche: 43114,
  scroll: 534352,
  "lukso-mainnet": 42,
  metisAndromeda: 1088,
  gnosis: 100,
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
    "fantom": { 
      ...createMainnetConfig("fantom-mainnet"),
      url: "https://fantom-pokt.nodies.app",
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
      url: `https://polygon-pokt.nodies.app`,
      // gasPrice: 450000000000,
    },
    avalanche: {
      ...createMainnetConfig("avalanche"),
      url: `https://api.avax.network/ext/bc/C/rpc`,
    },
    scroll: {
      ...createMainnetConfig("scroll"),
      url: `https://1rpc.io/scroll`,
    },
    "filecoin-mainnet": {
      ...createMainnetConfig("filecoin-mainnet"),
      url: `https://api.node.glif.io`,
    },
    "lukso-mainnet": {
      ...createMainnetConfig("lukso-mainnet"),
      url: "https://42.rpc.thirdweb.com",
    },
    metisAndromeda: {
      ...createMainnetConfig("metisAndromeda"),
      url: `https://andromeda.metis.io/?owner=1088`,
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
    fuji: {
      ...createTestnetConfig("fuji"),
      url: `https://api.avax-test.network/ext/bc/C/rpc`,
    },
    "filecoin-calibration": {
      ...createTestnetConfig("filecoin-calibration"),
      url: `https://api.calibration.node.glif.io/rpc/v1`,
    },
    "sei-devnet": {
      ...createTestnetConfig("sei-devnet"),
      url: `https://evm-rpc-arctic-1.sei-apis.com`,
    },
    "sei-mainnet": {
      ...createMainnetConfig("sei-mainnet"),
      url: `https://evm-rpc.sei-apis.com`,
    },
    "lukso-testnet": {
      ...createTestnetConfig("lukso-testnet"),
      url: "https://4201.rpc.thirdweb.com",
    },
    "gnosis": {
      ...createMainnetConfig("gnosis"),
      url: "https://rpc.gnosischain.com",
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
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      goerli: process.env.ETHERSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      optimisticEthereum: process.env.OPTIMISTIC_ETHERSCAN_API_KEY || "",
      optimisticGoerli: process.env.OPTIMISTIC_ETHERSCAN_API_KEY || "",
      ftmTestnet: process.env.FTMSCAN_API_KEY || "",
      opera: process.env.FTMSCAN_API_KEY || "",
      "celo-mainnet": process.env.CELOSCAN_API_KEY || "",
      "celo-testnet": process.env.CELOSCAN_API_KEY || "",
      base: process.env.BASESCAN_API_KEY || "",
      "base-testnet": process.env.BASESCAN_API_KEY || "",
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      mumbai: process.env.POLYGONSCAN_API_KEY || "",
      "arbitrum-mainnet": process.env.ARBITRUMSCAN_API_KEY || "",
      "arbitrum-sepolia": process.env.ARBITRUMSCAN_API_KEY || "",
      "optimism-sepolia": process.env.OPTIMISTIC_ETHERSCAN_API_KEY || "",
      "filecoin-mainnet": process.env.FILECOIN_ETHERSCAN_API_KEY || "",
      "filecoin-calibration": "no-api-key-needed",
      fuji: "no-api-key-needed",
      avalanche: "no-api-key-needed",
      scroll: process.env.SCROLLSCAN_API_KEY || "",
      "sei-mainnet": process.env.SEITRACE_API_KEY || "",
      "lukso-mainnet": "no-api-key-needed",
      "lukso-testnet": "no-api-key-needed",
      metisAndromeda: "no-api-key-needed",
      xdai: process.env.GNOSISSCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "fuji",
        chainId: chainIds["fuji"],
        urls: {
          apiURL:
            "https://api.avascan.info/v2/network/testnet/evm/43113/etherscan",
          browserURL: "https://testnet.avascan.info/blockchain/c",
        },
      },
      {
        network: "avalanche",
        chainId: chainIds["avalanche"],
        urls: {
          apiURL:
            "https://api.avascan.info/v2/network/mainnet/evm/43114/etherscan",
          browserURL: "https://avascan.info/blockchain/c",
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
      {
        network: "filecoin-calibration",
        chainId: chainIds["filecoin-calibration"],
        urls: {
          apiURL: "https://calibration.filfox.info/api/v1/tools/verifyContract",
          browserURL: "https://calibration.filfox.info",
        },
      },
      {
        network: "filecoin-mainnet",
        chainId: chainIds["filecoin-mainnet"],
        urls: {
          apiURL: "https://api.node.glif.io",
          browserURL: "https://filscan.io",
        },
      },
      {
        network: "scroll",
        chainId: chainIds["scroll"],
        urls: {
          apiURL: "https://api.scrollscan.com/api",
          browserURL: "https://scrollscan.com/",
        },
      },
      {
        network: "sei-devnet",
        chainId: chainIds["sei-devnet"],
        urls: {
          apiURL: "",
          browserURL: "", // TODO
        },
      },
      {
        network: "sei-mainnet",
        chainId: chainIds["sei-mainnet"],
        urls: {
          apiURL: "https://seitrace.com/api",
          browserURL: "https://seitrace.com/",
        },
      },
      {
        network: "lukso-testnet",
        chainId: chainIds["lukso-testnet"],
        urls: {
          apiURL: "https://explorer.execution.testnet.lukso.network/api",
          browserURL: "https://explorer.execution.testnet.lukso.network/",
        },
      },
      {
        network: "lukso-mainnet",
        chainId: chainIds["lukso-mainnet"],
        urls: {
          apiURL: "https://explorer.execution.mainnet.lukso.network/api",
          browserURL: "https://explorer.execution.mainnet.lukso.network/",
        },
      },
      {
        network: "metisAndromeda",
        chainId: chainIds["metisAndromeda"],
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/mainnet/evm/1088/etherscan",
          browserURL: "https://explorer.metis.io",
        },
      }
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