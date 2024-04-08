import hre, { ethers } from "hardhat";
import { Validator } from "../../scripts/utils/Validator";
import { Args, logPink } from "../../scripts/utils/deployProxy";
import { Deployments, verifyContract } from "../../scripts/utils/scripts";
import { Provider, Wallet } from "zksync-ethers";
import { Addressable, AbiCoder, hexlify, concat } from "ethers";

const deployContractUsingFactoryWithBytecodeOnEra = async (
  contractFactoryAddress: string | Addressable,
  bytecode: string,
  contractName: string,
  version: string,
  constructorArgs?: Args,
): Promise<string> => {

  // const provider = new Provider("https://sepolia.era.zksync.dev");

  // const deployerAddress = new Wallet(process.env.DEPLOYER_PRIVATE_KEY as string, provider);

  // const ContractArtifact = await hre.artifacts.readArtifact("ContractFactory");

  // const deployerContract = new ethers.Contract(
  //   contractFactoryAddress,
  //   ContractArtifact.abi,
  //   deployerAddress
  // );

  // let encodedParams = null;

  // if (constructorArgs) {
  //   encodedParams = new AbiCoder().encode(
  //     constructorArgs.types,
  //     constructorArgs.values
  //   );
  // }

  // // Combine the encoded parameters
  // const creationCodeWithConstructor = encodedParams
  //   ? hexlify(concat([bytecode, encodedParams]))
  //   : bytecode;

  // let contractAddress: string = "";

  // try {
  //   // get the strategy address
  //   contractAddress = await deployerContract.deploy.staticCall(
  //     contractName,
  //     version,
  //     creationCodeWithConstructor
  //   );

  //   // Deploy the contract and get the transaction response
  //   const txResponse = await deployerContract.deploy(
  //     contractName,
  //     version,
  //     creationCodeWithConstructor
  //   );

  //   // Wait for the transaction to be mined
  //   await txResponse.wait();

  //   logPink(
  //     "Contract " + contractName + " deployed at address: " + contractAddress
  //   );
  // } catch (error) {
  //   logPink(
  //     "Error calling deploy() function for contract " +
  //       contractName +
  //       "\n" +
  //       error
  //   );
  // }

  // return "contractAddress";
  return "test";
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

  const hashBytesStrategyName = ethers.keccak256(
    new ethers.AbiCoder().encode(["string"], [strategyName + version]),
  );

  const objToWrite = {
    id: hashBytesStrategyName,
    name: strategyName,
    version: version,
    address: impl.toString(),
    deployerAddress: deployerAddress.address,
  };

  deployments.write(objToWrite);

  await verifyContract(impl, [...values]);

  const validator = await new Validator(strategyName, impl);
  await validator.validate("getAllo", [], alloAddress);
  await validator.validate("getStrategyId", [], hashBytesStrategyName);

  return impl.toString();
}