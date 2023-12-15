import hre, { ethers, upgrades } from "hardhat";
import {
  Deployments,
  confirmContinue,
  getImplementationAddress,
  verifyContract,
} from "../../utils/scripts";

export async function upgradeRegistry() {
  const network = await ethers.provider.getNetwork();
  const networkName = hre.network.name;
  let account;
  let accountAddress;
  const chainId = Number(network.chainId);

  account = (await ethers.getSigners())[0];
  accountAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(accountAddress);

  const deployments = new Deployments(chainId, "registry");
  const proxyAddress = deployments.getAllo();

  console.log(`This script upgrades the Registry contract on ${networkName}`);

  await confirmContinue({
    contract: "Upgrading Registry",
    chainId: network.chainId,
    network: network.name,
    account: accountAddress,
    balance: ethers.formatEther(balance),
    proxy: proxyAddress,
  });

  console.log("Upgrading Registry...");

  const RegistryV2 = await ethers.getContractFactory("Registry", account);
  const instance = await upgrades.upgradeProxy(proxyAddress, RegistryV2);

  await instance.waitForDeployment();

  const implementation = await getImplementationAddress(
    instance.target as string
  );

  const objectToWrite = deployments.get(chainId);
  objectToWrite.implementation = implementation;
  deployments.write(objectToWrite);

  verifyContract(implementation, []);

  console.log("Registry Proxy Upgraded at:", instance.target);
  console.log("Registry implementation updated to:", implementation);
}

upgradeRegistry().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/upgrades/upgradeRegistry.ts --network sepolia
