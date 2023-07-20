import "dotenv/config";
import readline from "readline";

// import {HDAccountsUserConfig, HttpNetworkUserConfig, NetworksUserConfig} from 'hardhat/types';

export function getMnemonic(networkName?: string): string {
  if (networkName) {
    const mnemonic = process.env["MNEMONIC_" + networkName.toUpperCase()];
    if (mnemonic && mnemonic !== "") {
      return mnemonic;
    }
  }

  const mnemonic = process.env.MNEMONIC;
  if (!mnemonic || mnemonic === "") {
    return "test test test test test test test test test test test junk";
  }
  return mnemonic;
}

export function accounts(networkName?: string): { mnemonic: string } {
  return { mnemonic: getMnemonic(networkName) };
}

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
  };

  return s;
}