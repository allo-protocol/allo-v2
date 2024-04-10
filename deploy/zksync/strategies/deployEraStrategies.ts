import hre, { ethers } from "hardhat";
import { Validator } from "../../../scripts/utils/Validator";
import { Args, logPink } from "../../../scripts/utils/deployProxy";
import { Deployments, verifyContract } from "../../../scripts/utils/scripts";
import { Wallet } from "zksync-ethers";
import { Addressable, AbiCoder, hexlify, concat } from "ethers";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

const deployContractUsingFactoryWithBytecodeOnEra = async (
  contractFactoryAddress: string | Addressable,
  bytecode: string,
  contractName: string,
  version: string,
  constructorArgs?: Args,
): Promise<string> => {

  const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY as string);

  const ContractArtifact = await hre.artifacts.readArtifact("ContractFactory");

  const deployerContract = new ethers.Contract(
    contractFactoryAddress,
    ContractArtifact.abi,
    deployerAddress
  );

  let encodedParams = null;

  if (constructorArgs) {
    encodedParams = new AbiCoder().encode(
      constructorArgs.types,
      constructorArgs.values
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
      creationCodeWithConstructor
    );

    // Deploy the contract and get the transaction response
    const txResponse = await deployerContract.deploy(
      contractName,
      version,
      creationCodeWithConstructor
    );

    // Wait for the transaction to be mined
    await txResponse.wait();

    logPink(
      "Contract " + contractName + " deployed at address: " + contractAddress
    );
  } catch (error) {
    logPink(
      "Error calling deploy() function for contract " +
        contractName +
        "\n" +
        error
    );
  }

  return contractAddress;
};

const deployContractUsingFactoryOnEra = async (
  deployerContract: string,
  contractName: string,
  version: string,
  constructorArgs?: Args
): Promise<string> => {

  const ImplementationFactory = await hre.artifacts.readArtifact(contractName);
  const implementationCreationCode = ImplementationFactory.bytecode;  
  const implementationAddress = await deployContractUsingFactoryWithBytecodeOnEra(
    deployerContract,
    implementationCreationCode,
    contractName,
    version,
    constructorArgs
  );

  return implementationAddress;
};

export async function deployEraStrategies(
  strategyName: string,
  version: string,
  additionalArgs?: Args,
): Promise<string> {
  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY as string);

  const fileName = strategyName.toLowerCase();
  const deployments = new Deployments(chainId, fileName);

  const alloAddress = deployments.getAllo();

  console.log(`
    ////////////////////////////////////////////////////
      Deploys ${strategyName}.sol on ${networkName}
    ////////////////////////////////////////////////////
  `);

  console.table({
    contract: `${strategyName}.sol`,
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress.address,
  });

  console.log(`Deploying ${strategyName}.sol`);

  const types = ["address", "string"].concat(additionalArgs?.types ?? []);
  const values = [alloAddress, strategyName + version].concat(
    additionalArgs?.values ?? [],
  );

  const impl = await deployContractUsingFactoryOnEra(
    deployments.getContractFactory(),
    strategyName,
    version,
    {
      types,
      values,
    },
  );

  // const hashBytesStrategyName = hre.ethers.keccak256(
  //   new hre.ethers.AbiCoder().encode(["string"], [strategyName + version]),
  // );

  const objToWrite = {
    id: "",
    name: strategyName,
    version: version,
    address: impl.toString(),
    deployerAddress: deployerAddress.address,
  };

  deployments.write(objToWrite);

  await verifyContract(impl, [...values]);

  const validator = await new Validator(strategyName, impl);
  await validator.validate("getAllo", [], alloAddress);
  // await validator.validate("getStrategyId", [], hashBytesStrategyName);

  return impl.toString();
}

export async function deployEraStrategyDirectly(
  strategyName: string,
  version: string,
  args: any = []
  ): Promise<string|Addressable> {

  const network = await hre.network.config;
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);

  const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY as string);

  const deploymentIo = new Deployments(chainId, "contractFactory");
 
  const fileName = strategyName.toLowerCase();
  const deployments = new Deployments(chainId, fileName);
  const alloAddress = deployments.getAllo();

  console.log(`
    ////////////////////////////////////////////////////
        Deploys ${strategyName}.sol on ${networkName}
    ////////////////////////////////////////////////////`
  );

  console.table({
    contract: `Deploy ${strategyName}.sol`,
    version: version,
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress.address,
  });

  console.log(`Deploying ${strategyName}.sol...`);

  const deployer = new Deployer(hre, deployerAddress);
  const artifact = await deployer.loadArtifact(
    strategyName
  );

  const strategyNameWithVersion = strategyName + version;

  const instance = await deployer.deploy(artifact, [alloAddress, strategyNameWithVersion, ...args]);
  const CONTRACT_ADDRESS = await instance.getAddress();

  console.log(`${artifact.contractName} was deployed to ${CONTRACT_ADDRESS}`);

  // const hashBytesStrategyName = ethers.keccak256(
  //   new ethers.AbiCoder().encode(["string"], [strategyName + version]),
  // );

  const objToWrite = {
    id: "",
    name: strategyName,
    version: version,
    address: instance.target,
    deployerAddress: deployerAddress.address,
  };
  deploymentIo.write(objToWrite);

  await verifyContract(CONTRACT_ADDRESS, [alloAddress, strategyNameWithVersion, ...args]);

  return instance.target;
}