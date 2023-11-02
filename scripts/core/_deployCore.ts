import hre from "hardhat";
import { deployAllo } from "./deployAllo";
import { deployContractFactory } from "./deployContractFactory";
import { deployRegistry } from "./deployRegistry";
import { transferProxyAdminOwnership } from "./transferProxyAdminOwnership";

export async function deployCore() {
  const networkName = hre.network.name;

  console.log(`
    ////////////////////////////////////////////////////
    Deploy core Allo V2 contracts to ${networkName}
    ======================================
    - ContractFactory (used for strategy deployments)
    - Registry
    - Allo
    - TransferProxyAdminOwnership
    ////////////////////////////////////////////////////
  `);

  // Registry
  deployRegistry().then((registryAddress) => {
    // ContractFactory
    deployContractFactory().then((deployedContract) => {
      // Allo
      deployAllo().then((alloAddress) => {
        transferProxyAdminOwnership().then(() => {
          // Log deployed addresses
          console.log(`
            ////////////////////////////////////////////////////
            Core Allo V2 deployed to:
            ======================================
            ContractFactory: ${deployedContract}
            Registry: ${registryAddress}
            Allo: ${alloAddress}
            DeploymentFactory: ${deployedContract}
            ////////////////////////////////////////////////////
          `);
        });
      });
    });
  });
}

deployCore().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
