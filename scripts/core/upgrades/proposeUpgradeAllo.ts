import hre, { ethers, defender } from "hardhat";
import {
  Deployments,
  verifyContract
} from "../../utils/scripts";


export async function proposeUpgradeAllo() {
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

  console.log(`This script proposes an upgrades the Allo contract on ${networkName} via defender`);

  console.table ({
    contract: "Proposing Upgrading Allo on Defender",
    chainId: network.chainId,
    network: network.name,
    account: accountAddress,
    balance: ethers.formatEther(balance),
    proxy: proxyAddress,
  });

  const AlloV2 = await ethers.getContractFactory("Allo", account);
  console.log("Preparing Allo upgrade proposal...");
  const proposal = await defender.proposeUpgrade(proxyAddress, AlloV2);
  console.log("Upgrade proposal created at:", proposal.url);
  const implementation = proposal!.metadata!.newImplementationAddress;

  const objectToWrite = deployments.get(chainId);
  objectToWrite.implementation = implementation;
  deployments.write(objectToWrite);

  verifyContract(implementation as string, []);

  console.log("Proposed upgrade for Allo Proxy:", objectToWrite.proxy);
  console.log("Proposed Implementation Address:", implementation);

}

proposeUpgradeAllo().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/upgrades/proposeUpgradeAllo.ts --network sepolia