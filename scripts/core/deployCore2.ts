import hre, { ethers } from "hardhat";
import { deployAllo } from "./deployAllo";
import { deployContractFactory } from "./deployContractFactory";
import { deployRegistry } from "./deployRegistry";
import {
  DeployProxyOptions,
  deployProxyUsingFactory,
} from "../utils/deployProxy";

async function deployCore() {
  const networkName = await hre.network.name;
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();

  console.log(`
    ////////////////////////////////////////////////////
    Deploy core Allo V2 contracts to ${networkName}
    ======================================
    - ContractFactory (used for strategy deployments)
    - Registry
    - Allo
    ////////////////////////////////////////////////////
  `);

  // ContractFactory
  //deployContractFactory().then((deployedContract) => {
  // Registry
  const deployedContract = "0x44c537e8892A3FF2Ac9643C347b49953faB36708";
  const registryOptions: DeployProxyOptions = {
    contractName: "Registry",
    version: "v2.0.9",
    initializerArgs: {
      types: ["address"],
      values: [deployerAddress],
    },
  };

  deployProxyUsingFactory(deployedContract, registryOptions).then(
    (registryAddresses) => {
      let registryAddress = registryAddresses.proxy;
      const alloOptions: DeployProxyOptions = {
        contractName: "Allo",
        version: "v2.0.9",
        initializerArgs: {
          types: ["address", "address", "uint256", "uint256"],
          values: [registryAddress, deployerAddress, 0, 0],
        },
      };

      deployProxyUsingFactory(deployedContract, alloOptions).then(
        (alloAddresses) => {
          let alloAddress = alloAddresses.proxy;
          console.log(`
            ////////////////////////////////////////////////////
            Core Allo V2 deployed to:
            ======================================
            ContractFactory: ${deployedContract}
            Registry: ${registryAddress}
            Allo: ${alloAddress}
            ////////////////////////////////////////////////////
          `);
        },
      );
    },
  );
  // });
}

deployCore().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
