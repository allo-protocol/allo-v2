import hre, { ethers, upgrades } from "hardhat";
import { Deployments, confirmContinue, getImplementationAddress, prettyNum, verifyContract } from "../utils/scripts";
import { alloConfig } from "../config/allo.config";

async function upgradeAllo() {
    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    let account;
    let accountAddress;
    const chainId = Number(network.chainId);

    account = (await ethers.getSigners())[0];
    accountAddress = await account.getAddress();
    const balance = await ethers.provider.getBalance(accountAddress);

    const deployments = new Deployments(chainId, "allo");
    const proxyAddress = deployments.getAllo();    

    console.log(`This script upgrades the Allo contract on ${networkName}`);

    await confirmContinue({
        contract: "Upgrading Allo",
        chainId: network.chainId,
        network: network.name,
        account: accountAddress,
        balance: prettyNum(balance.toString()),
        proxyAddress: proxyAddress,
      });

    console.log("Upgrading Allo...");

    const AlloV2 = await ethers.getContractFactory("Allo", account);
    const instance = await upgrades.upgradeProxy(proxyAddress, AlloV2);

    await instance.waitForDeployment();
    await new Promise((r) => setTimeout(r, 20000));
  
    const implementation = await getImplementationAddress(
      instance.target as string,
    );

    const objectToWrite =  deployments.get(chainId);
    objectToWrite.alloImplementation = implementation;
    deployments.write(objectToWrite);
  
    verifyContract(implementation, []);
    
    console.log("Allo Proxy Upgraded at:", instance.target);
    console.log("Registry implementation updated to:", implementation);
}

upgradeAllo().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/core/upgradeAllo.ts --network sepolia