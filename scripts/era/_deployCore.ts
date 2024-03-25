import * as hre from "hardhat";
import dotenv from "dotenv";
import { deployAllo } from "./deployAllo";
import { deployRegistry } from "./deployRegistry";
import { deployContractFactory } from "./deployContractFactory";
// import { deployContract } from "./utils";

dotenv.config();

// export async function deployCore() {
//   const contractArtifactName = "Greeter";
//   const constructorArguments = ["Hi there!"];
//   await deployContract(contractArtifactName, constructorArguments);
// }

async function deployCore() {
        // const network = await hre.network.config;
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