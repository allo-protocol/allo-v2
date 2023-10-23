import { ethers, upgrades } from "hardhat";
import { registryConfig } from "../config/registry.config";
import { confirmContinue, prettyNum } from "../utils/scripts";

async function upgradeRegistry() {
  const network = await ethers.provider.getNetwork();
  let account;
  let accountAddress;
  //  const blocksToWait = hre.network.name === "localhost" ? 0 : 10;
  const chainId = Number(network.chainId);
  const registryParams = registryConfig[chainId];

  account = (await ethers.getSigners())[0];
  accountAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(accountAddress);

  console.log(`This script upgrades the Registryontract on ${network.name}`);

  await confirmContinue({
    contract: "Upgrading Registry",
    chainId: network.chainId,
    network: network.name,
    account: accountAddress,
    balance: prettyNum(balance.toString()),
    proxyAddress: registryParams.registryProxy,
  });

  console.log("Upgrading Registry.");

  const Registry = await ethers.getContractFactory("Registry", account);
  const instance = await upgrades.upgradeProxy(
    registryParams.registryProxy,
    Registry
  );
  // console.log("tx hash", instance.deployTransaction);
  // await instance.deployed(blocksToWait);

  // const gas = await instance.deployTransaction.estimateGas();
  // console.log(`gas used: ${gas}`)
  console.log("Registrypgraded");
}

upgradeRegistry().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/upgradeRegistry.ts --network sepolia
