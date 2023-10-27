import hre, { ethers, defender } from "hardhat";
import {
  Deployments,
  confirmContinue,
  verifyContract,
} from "../../utils/scripts";

export async function proposeUpgradeRegistry() {
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

  console.log(`This script proposes an upgrades the Registry contract on ${networkName} via defender`);

  await confirmContinue({
    contract: "Proposing Upgrading Registry on Defender",
    chainId: network.chainId,
    network: network.name,
    account: accountAddress,
    balance: ethers.formatEther(balance),
    proxy: proxyAddress,
  });

  const RegistryV2 = await ethers.getContractFactory("Registry", account);
  console.log("Preparing Allo upgrade proposal...");
  const proposal = await defender.proposeUpgrade(proxyAddress, RegistryV2);
  console.log("Upgrade proposal created at:", proposal.url);
  const implementation = proposal!.metadata!.newImplementationAddress;

  const objectToWrite = deployments.get(chainId);
  objectToWrite.implementation = implementation;
  deployments.write(objectToWrite);

  verifyContract(implementation as string, []);

  console.log("Proposed upgrade for Registry Proxy:", objectToWrite.proxy);
  console.log("Proposed Implementation Address:", implementation);

}

proposeUpgradeRegistry().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/upgrades/proposeUpgradeRegistry.ts --network sepolia
