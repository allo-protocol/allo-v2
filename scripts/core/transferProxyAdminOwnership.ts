import hre, { ethers, upgrades } from "hardhat";
import { commonConfig } from "../config/common.config";
import {
  Deployments,
} from "../utils/scripts";

export async function transferProxyAdminOwnership() {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(deployerAddress);

  const alloDeployments = new Deployments(chainId, "allo");
  const registryDeployments = new Deployments(chainId, "registry");

  const alloObject = alloDeployments.get(chainId);
  const registryObject = registryDeployments.get(chainId);

  // Get ProxyAdmin address
  const proxyAdmin = await upgrades.erc1967.getAdminAddress(alloObject.proxy);  

  let proxyAdminOwner = commonConfig[chainId].proxyAdminOwner as string;

  const abi = [ "function owner() view returns (address result)"]
  const ProxyAdminInstance = new ethers.Contract(proxyAdmin, abi, ethers.provider);
  const currentProxyAdminOwner = await ProxyAdminInstance.owner();

  if (proxyAdminOwner && currentProxyAdminOwner !== proxyAdminOwner) {
    console.log("Current Proxy Admin Owner: ", currentProxyAdminOwner);
    console.log(`
        ////////////////////////////////////////////////////
            TransferProxyAdminOwnership on ${networkName}
        ////////////////////////////////////////////////////
      `);

    console.table({
      contract: "TransferProxyAdminOwnership",
      chainId: chainId,
      network: networkName,
      allo: alloObject.proxy,
      registry: registryObject.proxy,
      proxyAdmin: proxyAdmin,
      deployerAddress: deployerAddress,
      newProxyAdminOwner: proxyAdminOwner,
      balance: ethers.formatEther(balance),
    });

    console.log("Transfering ProxyAdminOwnership...");
    await upgrades.admin.transferProxyAdminOwnership(proxyAdminOwner);

    console.log("Proxy Admin Owner Transferred to: ", proxyAdminOwner);

    alloObject.proxyAdminOwner = proxyAdminOwner;
    alloDeployments.write(alloObject);

    registryObject.proxyAdminOwner = proxyAdminOwner;
    registryDeployments.write(registryObject);
  } else {
    console.log("Proxy Admin Owner is already set to: ", proxyAdminOwner);
  }

  return true;
}

// Check if this script is the main module (being run directly)
if (require.main === module) {
  transferProxyAdminOwnership().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/transferProxyAdminOwnership.ts --network sepolia
