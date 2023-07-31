import hre from "hardhat";
import { deployRegistry } from "./deployRegistry";
import { deployAllo } from "./deployAllo";

async function deployCore() {
  const networkName = await hre.network.name;

  console.log(`
    ////////////////////////////////////////////////////
    Deploy core Allo V2 contracts to ${networkName}
    ======================================
    - Registry
    - Allo
    ////////////////////////////////////////////////////`
  );

  deployRegistry().then(registryAddress => {

    deployAllo(registryAddress!).then(alloAddress => {
        console.log(`
          ////////////////////////////////////////////////////
          Core Allo V2 deployed to:
          ======================================
          Registry: ${registryAddress}
          Allo: ${alloAddress}
          ////////////////////////////////////////////////////`
        );
    });
  })

}

deployCore().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});