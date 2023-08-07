import hre from "hardhat";
import { deployRegistry } from "./deployRegistry";
import { deployAllo } from "./deployAllo";
import { deployContractFactory } from "./deployContractFactory";

async function deployCore() {
  const networkName = await hre.network.name;

  console.log(`
    ////////////////////////////////////////////////////
    Deploy core Allo V2 contracts to ${networkName}
    ======================================
    - ContractFactory (used for strategy deployments)
    - Registry
    - Allo
    ////////////////////////////////////////////////////`
  );

  // ContractFactory
  deployContractFactory().then(deployedContract => {
    // Registry
    deployRegistry().then(registryAddress => {
      // Allo
      deployAllo(registryAddress.toString()).then(alloAddress => {
          // Log deployed addresses
          console.log(`
            ////////////////////////////////////////////////////
            Core Allo V2 deployed to:
            ======================================
            ContractFactory: ${deployedContract}
            Registry: ${registryAddress}
            Allo: ${alloAddress}
            ////////////////////////////////////////////////////`
          );
        });
    });
  })

}

deployCore().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});