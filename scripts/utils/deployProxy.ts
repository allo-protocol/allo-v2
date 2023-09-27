import hre, { ethers, upgrades } from "hardhat";
import { AbiCoder, Addressable, concat, hexlify } from "ethers";

import ProxyAdmin from "@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol/ProxyAdmin.json";
import TransparentUpgradeableProxy from "@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json";
import { Manifest } from "@openzeppelin/upgrades-core";

export type Args = {
  types: Array<string>;
  values: Array<any>;
};

export type DeployProxyOptions = {
  contractName: string;
  version: string;
  constructorArgs?: Args;
  initializerArgs?: Args;
};

export type ProxyAddresses = {
  implementation: string;
  proxy: string;
};

export const deployProxyUsingFactory = async (
  contractFactoryAddress: string | Addressable,
  deployProxyOptions: DeployProxyOptions,
): Promise<ProxyAddresses> => {
  const networkName = hre.network.name;

  const contractName = deployProxyOptions.contractName;
  const version = deployProxyOptions.version;

  logPink(`Deploys ${contractName}.sol with proxy on ${networkName}..`);

  let proxyAdmin: string = "";
  const manifest = await Manifest.forNetwork(hre.network.provider);

  if (await manifest.getAdmin()) {
    proxyAdmin = (await manifest.getAdmin())!.address;
  } else {
    proxyAdmin = await deployContractUsingFactory(
      contractFactoryAddress,
      ProxyAdmin.bytecode,
      "ProxyAdmin",
      version,
    );
  }

  const ImplementationFactory = await ethers.getContractFactory(contractName);
  const implementationCreationCode = ImplementationFactory.bytecode;
  const implementationAddress = await deployContractUsingFactory(
    contractFactoryAddress,
    implementationCreationCode,
    "Implementation " + contractName,
    version,
    deployProxyOptions.constructorArgs,
  );

  const fragment = ImplementationFactory.interface.getFunction("initialize");

  const transparentProxyAddress: string = await deployContractUsingFactory(
    contractFactoryAddress,
    TransparentUpgradeableProxy.bytecode,
    "TransparentUpgradeableProxy " + contractName,
    version,
    {
      types: ["address", "address", "bytes"],
      values: [
        implementationAddress,
        proxyAdmin,
        deployProxyOptions.initializerArgs && fragment
          ? ImplementationFactory.interface.encodeFunctionData(
              fragment,
              deployProxyOptions.initializerArgs.values,
            )
          : "0x",
      ],
    },
  );

  await upgrades.forceImport(transparentProxyAddress, ImplementationFactory, {
    kind: "transparent",
  });

  return {
    implementation: implementationAddress,
    proxy: transparentProxyAddress,
  };
};

const deployContractUsingFactory = async (
  contractFactoryAddress: string | Addressable,
  bytecode: string,
  contractName: string,
  version: string,
  constructorArgs?: Args,
): Promise<string> => {
  const ContractFactory = await hre.ethers.getContractFactory(
    "ContractFactory",
  );
  // Attach the deployed Deployer contract
  const deployerContract: any = ContractFactory.attach(contractFactoryAddress);

  let encodedParams = null;

  if (constructorArgs) {
    encodedParams = new AbiCoder().encode(
      constructorArgs.types,
      constructorArgs.values,
    );
  }

  // Combine the encoded parameters
  const creationCodeWithConstructor = encodedParams
    ? hexlify(concat([bytecode, encodedParams]))
    : bytecode;

  let contractAddress: string = "";

  try {
    // get the strategy address
    contractAddress = await deployerContract.deploy.staticCall(
      contractName,
      version,
      creationCodeWithConstructor,
    );

    // Deploy the contract and get the transaction response
    const txResponse = await deployerContract.deploy(
      contractName,
      version,
      creationCodeWithConstructor,
    );

    // Wait for the transaction to be mined
    await txResponse.wait();

    logPink(
      "Contract " + contractName + " deployed at address: " + contractAddress,
    );
  } catch (error) {
    logPink("Error calling deploy() function. \n" + error);
  }

  return contractAddress;
};

function logPink(text: string) {
  console.log("\x1b[35m%s\x1b[0m", text);
}
