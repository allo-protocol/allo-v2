import { ethers } from "hardhat";
import { strategyConfig } from "../config/strategies.config";
import { deployStrategies, deployStrategyDirectly } from "./deployStrategies";

export const deployDirectAllocation = async () => {
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  const strategyParams = strategyConfig[chainId]["direct-allocation"];

  // await deployStrategies(strategyParams.name, strategyParams.version, true);
  await deployStrategyDirectly(
    strategyParams.name,
    strategyParams.version,
    [],
    true,
  );
};

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployDirectAllocation().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}


```
Direct Allocation 
------

Optimism 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602
Arbitrum 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602
Celo 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602
Polygon
Base 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602
Avalanche 0x86b4329E7CB8674b015477C81356420D79c71A53
Scroll 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602
Fantom 0x1E18cdce56B3754c4Dca34CB3a7439C24E8363de
Mainnet 0x56662F9c0174cD6ae14b214fC52Bd6Eb6B6eA602
Sei 0x1cfa7A687cd18b99D255bFc25930d3a0b05EB00F
Lukso  0xeB6325d9daCD1E46A20C02F46E41d4CAE45C0980
Zksync
```