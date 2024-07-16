import hre, { ethers } from "hardhat";
import { ZeroAddress} from "ethers";

export async function createDirectAllocationPool() {

    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const account = (await ethers.getSigners())[0];
    const deployerAddress = await account.getAddress();

    const balance = await ethers.provider.getBalance(deployerAddress);

    const allo = "0x1133eA7Af70876e64665ecD07C0A0476d09465a1";

    console.table({
        contract: "allo: create pool",
        chainId: chainId,
        network: networkName,
        deployerAddress: deployerAddress,
        allo: allo,
        balance: ethers.formatEther(balance)
    });

    console.log("Creating pool...");
    const instance = await ethers.getContractAt('Allo', allo);

    await instance.createPool(
        '0x0fb3e7500d6ed84054b748dc2826b611c8d6d875dab3f769738951fdb47dc601', // _profileId
        '0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602', // _strategy
        "0x",   // _initStrategyData
        ZeroAddress, // _token
        0, // _amount
        {
            protocol: 0,
            pointer: ""
        }, // _metadata
        ['0xB8cEF765721A6da910f14Be93e7684e9a3714123'] // _managers
    );

    console.log("pool created at:", instance);
  
    return instance.target;
}

createDirectAllocationPool().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/createDirectAllocationPool.ts --network sepolia