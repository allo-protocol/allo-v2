import "dotenv/config";
import { Addressable } from "ethers";
import fs from "fs";
import hre, { upgrades } from "hardhat";
import readline from "readline";

// --- User verification ---
// Helper method for waiting on user input. Source: https://stackoverflow.com/a/50890409
export async function waitForInput(query: string): Promise<unknown> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) =>
    rl.question(query, (ans) => {
      rl.close();
      resolve(ans);
    }),
  );
}

export async function confirmContinue(params: Record<string, unknown>) {
  console.log("\nPARAMETERS");
  console.table(params);

  const response = await waitForInput("\nDo you want to continue? y/N\n");
  if (response !== "y")
    throw new Error("Aborting script: User chose to exit script");
  console.log("\n");
}

export const verifyContract = async (
  contractAddress: string | Addressable,
  verifyArgs: string[],
): Promise<boolean> => {
  console.log("\nVerifying contract...");
  await new Promise((r) => setTimeout(r, 20000));
  try {
    await hre.run("verify:verify", {
      address: contractAddress.toString(),
      constructorArguments: verifyArgs,
      noCompile: true,
    });
  } catch (e) {
    console.log(e);
  }
  return true;
};

export const getImplementationAddress = async (proxyAddress: string) => {
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(
    proxyAddress,
  );

  return implementationAddress;
};

export class Deployments {
  contractName: string;
  path: string;
  configObject: any;
  chainId: number;

  constructor(chainId: number, contractName: string) {
    this.contractName = contractName;
    this.chainId = chainId;
    this.path = `scripts/deployments/${contractName}.deployment.json`;
    this.configObject = this.readFile(this.contractName);
  }

  private readFile = (name: string) => {
    let configFile;
    const path = `scripts/deployments/${name}.deployment.json`;
    try {
      configFile = fs.readFileSync(path);
    } catch {
      configFile = "{}";
    }
    return JSON.parse(configFile.toString());
  };

  public write = (objToWrite: Object) => {
    this.configObject[this.chainId] = objToWrite;

    fs.writeFileSync(this.path, JSON.stringify(this.configObject, null, 2));
  };

  public get = (chainId: number) => {
    return this.configObject[chainId];
  };

  public getRegistry = (): string => {
    const obj = this.readFile("registry");
    const registryAddress = obj[this.chainId].proxy ?? "";

    return registryAddress;
  };

  public getAllo = (): string => {
    const obj = this.readFile("allo");
    const alloAddress = obj[this.chainId].proxy ?? "";

    return alloAddress;
  };

  public getContractFactory = (): string => {
    const obj = this.readFile("contractFactory");
    const contractFactoryAddress = obj[this.chainId].address ?? "";

    return contractFactoryAddress;
  };
}

export const delay = (ms: number) => new Promise((res) => setTimeout(res, ms));
