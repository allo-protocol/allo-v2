import hre from "hardhat";
import { deployRegistry } from "./deployRegistry";
import { deployAllo } from "./deployAllo";
import { deployDeployer } from "./deployDeployer";

async function deployCore() {
  const networkName = await hre.network.name;

  console.log(`
    ////////////////////////////////////////////////////
    Deploy core Allo V2 contracts to ${networkName}
    ======================================
    - Registry
    - Allo
    - Deployer (used for strategy deployments)
    ////////////////////////////////////////////////////`
  );

  // Registry
  deployRegistry().then(registryAddress => {
    // Allo
    deployAllo(registryAddress.toString()).then(alloAddress => {
        // Deployer
        deployDeployer().then(deployerAddress => {

          // Log deployed addresses
          console.log(`
            ////////////////////////////////////////////////////
            Core Allo V2 deployed to:
            ======================================
            Registry: ${registryAddress}
            Allo: ${alloAddress}
            Deployer: ${deployerAddress}
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