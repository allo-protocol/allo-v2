import hre, { ethers, upgrades } from "hardhat";
import {
  Deployments,
  getImplementationAddress,
  verifyContract
} from "../../utils/scripts";

export async function upgradeAllo() {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  let account;
  let accountAddress;
  const chainId = Number(network.chainId);

  account = (await ethers.getSigners())[0];
  accountAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(accountAddress);

  const deployments = new Deployments(chainId, "allo");
  const proxyAddress = deployments.getAllo();

  console.log(`This script upgrades the Allo contract on ${networkName}`);

  console.table ({
    contract: "Upgrading Allo",
    chainId: network.chainId,
    network: network.name,
    account: accountAddress,
    balance: ethers.formatEther(balance),
    proxy: proxyAddress,
  });

  console.log("Upgrading Allo...");

  const AlloV2 = await ethers.getContractFactory("Allo", account);
  const instance = await upgrades.upgradeProxy(proxyAddress, AlloV2);

  await instance.waitForDeployment();

  const implementation = await getImplementationAddress(
    instance.target as string
  );

  const objectToWrite = deployments.get(chainId);
  objectToWrite.implementation = implementation;
  deployments.write(objectToWrite);

  verifyContract(implementation, []);

  console.log("Allo Proxy Upgraded at:", instance.target);
  console.log("Allo implementation updated to:", implementation);
}

upgradeAllo().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/upgrades/upgradeAllo.ts --network sepolia