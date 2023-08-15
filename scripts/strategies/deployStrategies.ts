import { AbiCoder, concat, hexlify } from "ethers";
import hre, { ethers } from "hardhat";
import { alloConfig } from "../config/allo.config";
import { deployerContractAddress } from "../config/strategies.config";
import { confirmContinue, prettyNum } from "../utils/scripts";

export async function deployStrategies(strategyName: string, version: string) {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const blocksToWait = networkName === "localhost" ? 0 : 5;
  const balance = await ethers.provider.getBalance(deployerAddress);

  console.log(`
    ////////////////////////////////////////////////////
      Deploys ${strategyName}.sol on ${networkName}
    ////////////////////////////////////////////////////`);

  await confirmContinue({
    contract: `${strategyName}.sol`,
    chainId: chainId,
    network: networkName,
    deployerAddress: deployerAddress,
    balance: prettyNum(balance.toString()),
  });

  console.log(`Deploying ${strategyName}.sol`);

  const DEPLOYER_CONTRACT_ADDRESS: string =
    deployerContractAddress[chainId].address;

  console.log("Deployer contract address: ", DEPLOYER_CONTRACT_ADDRESS);

  // Get signer information
  const [deployer]: any = await hre.ethers.getSigners();
  console.log("Calling contract with the account:", deployer.address);

  // Get contract instance
  const DeployerContract = await hre.ethers.getContractFactory("ContractFactory");
  // Attach the deployed Deployer contract
  const deployerContract: any = DeployerContract.attach(
    deployerContractAddress[chainId].address,
  );

  let creationCode;
  let creationCodeWithConstructor;

  try {
    const Strategy = await ethers.getContractFactory(strategyName);
    //get bytecode of strategy
    creationCode = Strategy.bytecode;

    const allo = alloConfig[chainId].alloProxy;
    const name = strategyName + version;

    //abi.encodePacked(creationCode, abi.encode(address(allo), "TestStrategy"))
    // Define the types of the data
    const types: Array<string> = ["address", "string"];

    // The data you're encoding
    const data: Array<any> = [allo, name];
    const encodedParams = new AbiCoder().encode(types, data);

    // Combine the encoded parameters
    creationCodeWithConstructor = hexlify(
      concat([creationCode, encodedParams]),
    );
  } catch (error) {
    console.log("Strategy name not found.", error);
  }

  // set the args
  // const MY_FUNCTION_ARGS: any = [
  //   strategyName,
  //   version,
  //   creationCode,
  // ]; // replace with your function arguments if any

  // Call the contract function
  try {
    // get the strategy address
    const strategyAddress = await deployerContract.deploy.staticCall(
      strategyName,
      version,
      creationCodeWithConstructor,
    );

    // Deploy the contract and get the transaction response
    const txResponse = await deployerContract.deploy(
      strategyName,
      version,
      creationCodeWithConstructor,
    );

    // Wait for the transaction to be mined
    await txResponse.wait();

    console.log("Strategy deployed at address: ", strategyAddress);
  } catch (error) {
    console.log("Error calling deploy() function. \n", error);
  }
}

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployStrategies.ts --network sepolia
