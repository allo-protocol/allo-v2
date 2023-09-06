import * as dotenv from "dotenv";

import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-upgradable";
import "@matterlabs/hardhat-zksync-verify";
import "@typechain/hardhat";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";

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
      ...createMainnetConfig(
        "zksync-mainnet",
        "https://zksync2-mainnet.zksync.io"
      ),
      zksync: true,
      ethNetwork: "mainnet",
    },

    // Test Networks
    "zksync-testnet": {
      ...createTestnetConfig(
        "zksync-testnet",
        "https://zksync2-testnet.zksync.dev"
      ),
      zksync: true,
      ethNetwork: "goerli",
      verifyURL:
        "https://zksync2-testnet-explorer.zksync.dev/contract_verification",
    },
  },
  defaultNetwork: "zksync-testnet",
  // @ts-ignore
  etherscan: {
    apiKey: {
      // @ts-ignore
      mainnet: process.env.ETHERSCAN_API_KEY,
      // @ts-ignore
      goerli: process.env.ETHERSCAN_API_KEY,
    }
  },
  zksolc: {
    version: "1.3.13",
    compilerSource: "binary",
    settings: {
      isSystem: true,
    },
  },
};

export default config;