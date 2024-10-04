import { ethers } from 'hardhat';
import { strategyConfig } from '../config/strategies.config';
import { deployStrategies } from './deployStrategies';
import { Contract, ContractFactory } from 'ethers';
import FunderNFTArtifact from '../../artifacts/contracts/strategies/hyperstaker/FunderNFT.sol/FunderNFT.json'; // Path to your compiled JSON file
//const gasLimit = 2000000;

export const deployHyperstakerStrategy = async () => {
  try {
    // Get the current network
    const network = await ethers.provider.getNetwork();
    const chainId = Number(network.chainId);
    const pendingTx = await ethers.provider.getTransactionCount(
      '0xbEf44b6e568be58764E9FDE362E8bfDC95299A6B',
      'pending'
    );

    console.log('pendingTx is ', pendingTx);

    // Load the strategy parameters for the "hyperstaker" strategy from the config file
    const strategyParams = strategyConfig[chainId]['hyperstaker'];

    const abi = FunderNFTArtifact.abi;
    const bytecode = FunderNFTArtifact.bytecode;

    // Get the signer used for deploying contracts
    const signer = (await ethers.getSigners())[0];

    // Create a ContractFactory instance for FunderNFT
    const FunderNFTFactory = new ethers.ContractFactory(abi, bytecode, signer);
    const deployTransaction = await FunderNFTFactory.getDeployTransaction();

    const estimatedTotalGasToDeploy = await signer.estimateGas(
      deployTransaction
    );
    //console.log('estimatedGas is ', estimatedTotalGasToDeploy);
    // Add a buffer to the gas limit (e.g., 10% extra)
    const gasLimit = (estimatedTotalGasToDeploy * 110n) / 100n; // Using BigInt arithmetic

    // Fetch current gas fee data (base fee and priority fee)
    const feeData = await ethers.provider.getFeeData();

    // Set higher gas fees - multiply by 1.1x - than the current ones for faster transaction
    const maxFeePerGas = feeData.maxFeePerGas
      ? (feeData.maxFeePerGas * 105n) / 100n
      : ethers.parseUnits('40', 'gwei'); // Use double or default 40 Gwei

    const maxPriorityFeePerGas = ethers.parseUnits('2', 'gwei'); // Set a higher priority fee (tip)

    // Estimate gas for the deployment transaction

    console.log('gasLimit is ', gasLimit);
    console.log('maxFeePerGas is ', maxFeePerGas);
    console.log('maxPriorityFeePerGas is ', maxPriorityFeePerGas);
    3000000000000000000;
    2497931717648000000;
    503986814007206740;
    1918531655206740;
    const funderNFTContract = await FunderNFTFactory.deploy({
      gasLimit,
      maxFeePerGas, // Set the higher max fee per gas
      maxPriorityFeePerGas, // Set the higher priority fee (tip),
      nonce: 2,
    });
    console.log('Deploying FunderNFT...');

    const deploymentTx = funderNFTContract.deploymentTransaction();
    console.log('FunderNFT deploymentTx hash is ', deploymentTx?.hash);
    // Wait for the contract to be deployed
    await funderNFTContract.waitForDeployment();
    console.log(`FunderNFT deployed at: ${funderNFTContract.target}`);

    // Now that the NFT is deployed, pass its address to the HyperstakerStrategy constructor
    const nftContractAddress = funderNFTContract.target;
    console.log('nftContractAddress is', nftContractAddress);

    // Now that the NFT is deployed, pass its address to the HyperstakerStrategy constructor
    console.log('nftContractAddress is ', nftContractAddress);

    // Define the additional arguments for the HyperstakerStrategy constructor
    const additionalArgs = {
      types: ['address'], // The additional argument type (nftContract)
      values: [nftContractAddress], // The actual NFT contract address to pass to the constructor
    };

    // Deploy the strategy using the deployStrategies function, passing the NFT contract address
    const deployedAddress = await deployStrategies(
      strategyParams.name, // Strategy name
      strategyParams.version, // Strategy version
      false, // Whether the strategy is cloneable or not
      additionalArgs // Additional arguments including the NFT contract address
    );

    console.log(`HyperstakerStrategy deployed at: ${deployedAddress}`);
  } catch (error) {
    console.error('Error deploying strategy:', error);
    process.exitCode = 1;
  }
};

// Check if this script is the main module (being run directly)
if (require.main === module) {
  deployHyperstakerStrategy().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
