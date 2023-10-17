import hre, { ethers, upgrades } from "hardhat";
import { registryConfig } from "../config/registry.config";
import { confirmContinue, prettyNum } from "../utils/scripts";

export async function deployRegistry() {
    const network = await ethers.provider.getNetwork();
    const networkName = hre.network.name;
    const chainId = Number(network.chainId);
    const account = (await ethers.getSigners())[0];
    const deployerAddress = await account.getAddress();
    const balance = await ethers.provider.getBalance(deployerAddress);

    console.log(`
        ////////////////////////////////////////////////////
                Deploys Registry.sol on ${networkName}
        ////////////////////////////////////////////////////
    `);

    await confirmContinue({
        contract: "Registry.sol",
        chainId: chainId,
        network: networkName,
        deployerAddress: deployerAddress,
        registryOwner: registryConfig[chainId].owner,
        balance: prettyNum(balance.toString())
    });

    console.log("Deploying Registry...");

    // const deployerContract = deployerContractAddress[chainId!].address;
    // const registryOptions: DeployProxyOptions = {
    //     contractName: "Registry",
    //     version: "v1.0.3",
    //     initializerArgs: {
    //         types: ["address"],
    //         values: [deployerAddress],
    //     },
    // };

    // const addresses = await deployProxyUsingFactory(deployerContract, registryOptions);

    const Registry = await ethers.getContractFactory("Registry");
    const instance = await upgrades.deployProxy(Registry, [
        registryConfig[chainId].owner
    ]);

    // await instance.deploymentTransaction()?.wait(blocksToWait);

    // await verifyContract(instance.target.toString(), [registryConfig[chainId].owner]);

    console.log("Registry proxy deployed to:", instance.target);
    // console.log("Registry implementation deployed to:", addresses.implementation)

    // return addresses;
}

deployRegistry().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/deployRegistry.ts --network sepolia