import * as dotenv from "dotenv";

import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-upgradable";
import "@matterlabs/hardhat-zksync-verify";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-preprocessor";
import "@typechain/hardhat";
import { HardhatUserConfig, subtask } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import fs from "fs";

dotenv.config();

const chainIds = {
  // local network
  "zksync-testnet": 280,

  // mainnet
  "zksync-mainnet": 324,
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
    "zksync-mainnet": {
      ...createMainnetConfig("zksync-mainnet", "https://mainnet.era.zksync.io"),
      zksync: true,
      ethNetwork: "mainnet",
    },

    // Test Networks
    "zksync-testnet": {
      ...createTestnetConfig(
        "zksync-testnet",
        "https://sepolia.era.zksync.dev"
      ),
      zksync: true,
      ethNetwork: "sepolia",
      verifyURL: "https://sepolia.explorer.zksync.io/contract_verification",
    },
  },
  defaultNetwork: "zksync-testnet",
  // @ts-ignore
  etherscan: {
    apiKey: {
      // @ts-ignore
      mainnet: process.env.ETHERSCAN_API_KEY,
      // @ts-ignore
      sepolia: process.env.ETHERSCAN_API_KEY,
    },
  },
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
  zksolc: {
    version: "latest",
    compilerSource: "binary",
    settings: {
      isSystem: true,
    },
  }
};

export default config;
