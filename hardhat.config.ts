import * as dotenv from "dotenv";

import "@nomicfoundation/hardhat-foundry";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-solhint";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import { HardhatUserConfig, task } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import "solidity-coverage";

dotenv.config();

const chainIds = {
  // local
  localhost: 31337,

  // testnet
  sepolia: 11155111,

  // mainnet
  mainnet: 1
};

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

/**
 * Generates hardhat network configuration the test networks.
 * @param network
 * @param url (optional)
 * @returns {NetworkUserConfig}
 */
function createTestnetConfig(
  network: keyof typeof chainIds,
  url: string
): NetworkUserConfig {
  return {
    accounts: [process.env.DEPLOYER_PRIVATE_KEY as string],
    chainId: chainIds[network],
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
  url: string
): NetworkUserConfig {
  return {
    accounts: [process.env.DEPLOYER_PRIVATE_KEY as string],
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
  paths: {
    tests: "./test/hardhat",
  },
  networks: {
    // ===============================
    // ====== Mainnet Networks =======
    // ===============================
    mainnet: createMainnetConfig(
      "mainnet",
      process.env.MAINNET_RPC_URL as string
    ),

    // ===============================
    // ======== Test Networks ========
    // ===============================
    sepolia: createTestnetConfig(
      "sepolia",
      process.env.SEPOLIA_RPC_URL as string
    ),

    // Localhost
    localhost: createTestnetConfig(
      "localhost",
      "http://127.0.0.1:8545"
    ),
  },

  gasReporter: {
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD"
  },

  etherscan: {
    apiKey: {
      // @ts-ignore
      mainnet: process.env.ETHERSCAN_API_KEY,
      // @ts-ignore
      sepolia: process.env.ETHERSCAN_API_KEY,
    },
  },
  abiExporter: abiExporter,
};

export default config;
