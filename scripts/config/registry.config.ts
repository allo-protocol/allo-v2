// NOTE: Update this file anytime a new Registry is deployed.

type RegistryConfig = {
  owner: string;
};

type DeployParams = Record<number, RegistryConfig>;

// NOTE: This will be the owner address for each registy on each network.
export const registryDeployParams: DeployParams = {
  11155111: {
    owner: "0x1fD06f088c720bA3b7a3634a8F021Fdd485DcA42",
  },
};
