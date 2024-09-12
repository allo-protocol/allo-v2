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
        '0x13ffe09671f07a4eb6bfcf96fa58d93bedabf721d26d0cc162f267504816f3db', // _profileId
        '0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602', // _strategy
        "0x",   // _initStrategyData
        ZeroAddress, // _token
        0, // _amount
        {
            protocol: 0,
            pointer: ""
        }, // _metadata
        ['0x8C180840fcBb90CE8464B4eCd12ab0f840c6647C'] // _managers
    );

    console.log("pool created on registry at:", instance.target);
  
    return instance.target;
}

createDirectAllocationPool().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

// Note: Deploy script to run in terminal:
// npx hardhat run scripts/createDirectAllocationPool.ts --network sepolia


// ```
// Direct Allocation 
// ------
// Network     | Strategy Address                           | Profile                                                            | Pool Id
// Optimism    | 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602 | 0x7136ff86ab8019eed172bc68658569ed7e9f58ec4ea95b68e18ca7f1670e35c0 | 58
// Arbitrum    | 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602 | 0x01279c5322a7ba281f02092da541a468ceafbe2a683944d798098fa2f21f4e90 | 390
// Celo        | 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602 | 0x13ae69f251a032000a44456bde4bd4b5abaca9d6b78e7c65a675064c168e3449 | 12
// Base        | 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602 | 0x4e9ac6efee79d2542611fa44d6bd92d7bfb8f3810f49df2e2ab5c10de6714dc2 | 36
// Avalanche   | 0x86b4329E7CB8674b015477C81356420D79c71A53 | 0xb7f0c57c1ef6a3ac657e454a0e7fc7ba76b66cb83644b02efd6d8a6e0548de43 | 15
// Scroll      | 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602 | 0x8296c82445f099fa9c70a2ce0f79a7b0454e3226e2efc205c4cb4e327380f357 | 22
// Fantom      | 0x1E18cdce56B3754c4Dca34CB3a7439C24E8363de | 0x1af71e26bc0e0ad8f24dc234d90da4b03ba5ba225c998ab30de03957b0dffdc2 | 4
// Mainnet     | 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602 | 0xb89425ca914da89f5da7a002dc7484c3a4eefe65034f0d8bba2144ef98b8e87d | 11
// Sei         | 0x1cfa7A687cd18b99D255bFc25930d3a0b05EB00F | 0xc283992812559f990f71ec8b7e85aa7cebc50d908a2c93f6e69c7daf03dfc800 | 8
// Lukso       | 0xeB6325d9daCD1E46A20C02F46E41d4CAE45C0980 | 0xea2ee6a4a803a669e1e1008e1b6993d073180bcddcc51f8f5d4fa89e9ae2894f | 3
// Metis       | 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602 | 0x13ffe09671f07a4eb6bfcf96fa58d93bedabf721d26d0cc162f267504816f3db | 1 
// Polygon     | | | |
// Zksync      | | | |
// ```