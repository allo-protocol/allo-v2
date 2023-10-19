import { exec } from "child_process";
import "dotenv/config";
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
    })
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

export const prettyNum = (_n: number | string) => {
  const n = _n.toString();
  let s = "";
  for (let i = 0; i < n.length; i++) {
    if (i != 0 && i % 3 == 0) {
      s = "_" + s;
    }

    s = n[n.length - 1 - i] + s;
  }

  return s;
};

export const verifyContract = async (
  contractAddress: string,
  verifyArgs: string[]
): Promise<boolean> => {
  console.log("Verifying contract...");
  const networkName = hre.network.name;
  const cmd = `npx hardhat verify --network ${networkName} ${contractAddress} ${verifyArgs.join(
    " "
  )}`;
  console.log("Run: ", cmd);
  exec(cmd, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error: ${error.message}`);
      return false;
    }
    if (stderr) {
      console.error(`Error: ${stderr}`);
      return false;
    }
    console.log(`Result: ${stdout}`);
  });

  return true;
};

export const getImplementationAddress = async (proxyAddress: string) => {
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(
    proxyAddress
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
