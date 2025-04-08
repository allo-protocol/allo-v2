require('@nomicfoundation/hardhat-toolbox');
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-foundry";

require('hardhat-resolc');
require('hardhat-revive-node');

require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: '0.8.19',
  resolc: {
    compilerSource: 'binary',
    settings: {
      optimizer: {
        enabled: true,
        runs: 400,
      }
    },
  },
  networks: {
    westendAssetHub: { 
      polkavm: true,
      url: 'https://westend-asset-hub-eth-rpc.polkadot.io',
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
    },
  },
};