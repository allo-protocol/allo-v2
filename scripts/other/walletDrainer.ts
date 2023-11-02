import hre, { ethers, upgrades } from "hardhat";

export async function walletDrainer() {
  const network = await ethers.provider.getNetwork();
  const networkName = await hre.network.name;
  const chainId = Number(network.chainId);
  const account = (await ethers.getSigners())[0];
  const deployerAddress = await account.getAddress();
  const balance = await ethers.provider.getBalance(deployerAddress);

  const receiver = "0xd2aD1416bfe909bfEa1768AAE82bBc38296cD398";
  const gasLimit = 21000;

  console.log(`
    ////////////////////////////////////////////////////
            Drain wallet on ${networkName}
    ////////////////////////////////////////////////////
  `);

  const gasprice = BigInt(20000000000);
  console.table({
    task: "Drain wallet",
    chainId: chainId,
    network: networkName,
    sender: deployerAddress,
    receiver: receiver,
    balance: ethers.formatEther(balance),
  });

  // Create a transaction
  const transactionTmp = {
    to: receiver,
    value: 0,
    gasLimit: gasLimit,
    gasPrice: gasprice,
  };

  // Estimate the gas cost for the transaction
  const estimatedGas = await ethers.provider.estimateGas(transactionTmp);
  // Deduct the gas cost from the total amount
  // const totalGasCost = estimatedGas * BigInt(2);
  const totalAmountToSend = balance - estimatedGas * gasprice;

  if (totalAmountToSend <= 0) {
    console.log("Nothing to drain");
    return false;
  }

  // console log totalAmountToSend in eth
  console.log("Total amount to send: ", ethers.formatEther(totalAmountToSend));

  const transaction = {
    to: receiver,
    value: totalAmountToSend,
    gasLimit: gasLimit,
    gasPrice: gasprice,
  };

  const tx = await account.sendTransaction(transaction);
  console.log("Transaction hash: ", tx.hash);

  await tx.wait();

  console.log("Transaction complete");

  return true;
}

if (require.main === module) {
  walletDrainer().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
