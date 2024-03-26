import * as hre from "hardhat";
import * as dotenv from "dotenv";
import { registryConfig } from "../scripts/config/registry.config";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-ethers";
import { Deployments, getImplementationAddress } from "../scripts/utils/scripts";

dotenv.config();

export default async function () {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(
    process.env.DEPLOYER_PRIVATE_KEY as string
  );

  const deployments = new Deployments(chainId, "registry");

  console.log(`
    ////////////////////////////////////////////////////
          Deploys Registry.sol on ${networkName}
    ////////////////////////////////////////////////////`
  );

  const registryParams = registryConfig[chainId];
  if (!registryParams) {
    throw new Error(`Registry params not found for chainId: ${chainId}`);
  }

  console.table({
    contract: "Registry.sol",
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress.address,
    registryOwner: registryParams.owner,
  });

  console.log("Deploying Registry...");

  const deployer = new Deployer(hre, deployerAddress);
  const Registry = await deployer.loadArtifact("Registry");
  const instance = await hre.zkUpgrades.deployProxy(
    deployer.zkWallet,
    Registry,
    [registryConfig[chainId].owner],
    { initializer: "initialize" }
  );

  await instance.waitForDeployment();
  const CONTRACT_ADDRESS = await instance.getAddress();

  // const implementation = await getImplementationAddress(
  //   instance.target as string,
  // );
  // const proxyAdmin = await hre.upgrades.erc1967.getAdminAddress(instance.target as string);
  // let proxyAdminOwner = account.address;

  console.log("Registry deployed to:", CONTRACT_ADDRESS);

  const objToWrite = {
    name: "Registry",
    // implementation: implementation,
    proxy: CONTRACT_ADDRESS,
    deployerAddress: deployerAddress,
    owner: registryParams.owner,
    // proxyAdmin: proxyAdmin,
    // proxyAdminOwner: proxyAdminOwner,
  };

  deployments.write(objToWrite);

  // await verifyContract(instance.target.toString(), []);
  // await verifyContract(implementation, []);

  return instance.address;
}

// deployRegistry().catch((error) => {
//     console.error(error);
//     process.exitCode = 1;
// });

// Note: Deploy script to run in terminal:
// npx hardhat compile --network zkSyncTestnet --config era.hardhat.config.ts
// npx hardhat deploy-zksync --network zkSyncTestnet --config era.hardhat.config.ts --script deployRegistry.ts
