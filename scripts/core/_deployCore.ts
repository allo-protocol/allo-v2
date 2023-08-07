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
    - Deployer (used for strategy deployments)
    - Registry
    - Allo
    ////////////////////////////////////////////////////`
  );

  // Deployer
  deployDeployer().then(deployerAddress => {
    // Registry
    deployRegistry().then(registryAddress => {
      // Allo
      deployAllo(registryAddress.toString()).then(alloAddress => {
          // Log deployed addresses
          console.log(`
            ////////////////////////////////////////////////////
            Core Allo V2 deployed to:
            ======================================
            Deployer: ${deployerAddress}
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