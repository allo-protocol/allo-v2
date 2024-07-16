import hre, { ethers } from "hardhat";
import { alloConfig } from "../config/allo.config";
import {AbiCoder} from "ethers";

export async function createPool() {

    const network = await ethers.provider.getNetwork();
    const networkName = await hre.network.name;
    const chainId = Number(network.chainId);

    const account = (await ethers.getSigners())[0];
    const deployerAddress = await account.getAddress();
    const blocksToWait = hre.network.name === "localhost" ? 0 : 5;

    const balance = await ethers.provider.getBalance(deployerAddress);

    const allo = alloConfig[chainId].alloProxy;

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

    const _currentTimestamp = (await ethers.provider.getBlock(
        await ethers.provider.getBlockNumber())
    )!.timestamp;

    const encoder = new AbiCoder();
    const initStrategyData = encoder.encode(
        ["bool", "bool", "uint256", "uint256", "uint256", "uint256", "address[]"],
        [
            true, // useRegistryAnchor
            true, // metadataRequired
            _currentTimestamp + 3600,   // 1 hour later   registrationStartTime
            _currentTimestamp + 432000, // 5 days later   registrationEndTime
            _currentTimestamp + 7200,   // 2 hours later  allocationStartTime
            _currentTimestamp + 864000, // 10 days later  allocaitonEndTime
            ['0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'] // allowed token
        ]
    );


    console.log(        '0xb2a02f1bb0d07456d929eb7bf31c49b69f756ba90f64c0288488fb1a4cd6abef', // _profileId
    '0xC88612a4541A28c221F3d03b6Cf326dCFC557C4E', // _strategy donationVotingMerkleStrategy
    initStrategyData,   // _initStrategyData
    '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // _token
    0, // _amount
    {
        protocol: 1,
        pointer: "bafybeia4khbew3r2mkflyn7nzlvfzcb3qpfeftz5ivpzfwn77ollj47gqi"
    }, // _metadata
    ['0xB8cEF765721A6da910f14Be93e7684e9a3714123'] // _managers
    );
    

    await instance.createPool(
        '0xb2a02f1bb0d07456d929eb7bf31c49b69f756ba90f64c0288488fb1a4cd6abef', // _profileId
        '0xC88612a4541A28c221F3d03b6Cf326dCFC557C4E', // _strategy donationVotingMerkleStrategy
        initStrategyData,   // _initStrategyData
        '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // _token
        0, // _amount
        {
            protocol: 1,
            pointer: "bafybeia4khbew3r2mkflyn7nzlvfzcb3qpfeftz5ivpzfwn77ollj47gqi"
        }, // _metadata
        ['0xB8cEF765721A6da910f14Be93e7684e9a3714123'] // _managers
    );

    console.log("pool created at:", instance);
  
    return instance.target;
}

createPool().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/createPool.ts --network sepolia