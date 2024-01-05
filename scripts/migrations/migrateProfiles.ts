import hre, { ethers } from "hardhat";
import { profileConfig } from "../config/profile.config";

export async function migrateProfiles() {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(deployerAddress);
  const gasLimit = 21000;
  const gasprice = chainId == 137 ? BigInt(350000000000) : BigInt(30000000000);

  console.log(`
    ////////////////////////////////////////////////////
            Migrate profiles on ${networkName}
    ////////////////////////////////////////////////////
  `);

  console.table({
    task: "Migrate profiles",
    chainId: chainId,
    network: networkName,
  });

  // Fetch projects from registry
  const registryAddress = profileConfig[chainId].v1RegistryAddress;

  console.log("Registry address: ", registryAddress);

  // Mutate/Create object to create the new profiles
}

if (require.main === module) {
  migrateProfiles().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
