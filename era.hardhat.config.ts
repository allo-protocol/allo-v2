import { HardhatUserConfig } from "hardhat/config";

import "@matterlabs/hardhat-zksync-node";
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";

import "@openzeppelin/hardhat-upgrades";
import "hardhat-preprocessor";

import fs from "fs";

const chainIds = {
  // local network
  localhost: 31337,

  // testnet
  "zksync-testnet": 300,

  // mainnet
  "zksync-mainnet": 324,
};

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

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
  },
  networks: {
    "zksync-testnet": {
      url: "https://sepolia.era.zksync.dev",
      ethNetwork: "sepolia",
      zksync: true,
      verifyURL:
        "https://explorer.sepolia.era.zksync.dev/contract_verification",
    },
    "zksync-mainnet": {
      url: "https://mainnet.era.zksync.io",
      ethNetwork: "mainnet",
      zksync: true,
      verifyURL:
        "https://zksync2-mainnet-explorer.zksync.io/contract_verification",
    },
  },
  defaultNetwork: "zksync-testnet",
  // @ts-ignore
  etherscan: {
    apiKey: {
      // @ts-ignore
      "zksync-testnet": process.env.ETHERSCAN_API_KEY,
      // @ts-ignore
      "zksync-mainnet": process.env.ETHERSCAN_API_KEY,
    },
  },
  customChains: [
    {
      network: "zksync-mainnet",
      chainId: chainIds["zksync-mainnet"],
      urls: {
        apiURL:
          "https://zksync2-mainnet-explorer.zksync.io/contract_verification",
        browserURL: "https://zksync2-mainnet-explorer.zksync.io",
      },
    },
    {
      network: "zksync-testnet",
      chainId: chainIds["zksync-testnet"],
      urls: {
        apiURL: "https://explorer.sepolia.era.zksync.dev/contract_verification",
        browserURL: "https://explorer.sepolia.era.zksync.dev",
      },
    },
  ],
  preprocess: {
    eachLine: () => ({
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
    deployPaths: ["./scripts/era"],
    artifacts: "./artifacts",
  },
  typechain: {
    outDir: "./artifacts/types",
    target: "ethers-v6",
  },
  zksolc: {
    version: "latest",
    settings: {
      // isSystem: true,
    },
  },
};

export default config;
