# Contract Upgrade Runbook/Research

#### Contract Owner Research:

##### 🚨 Use a Separate Account for the Transparent Proxy Admin:
The proxy admin and logic governance should be separate addresses to prevent loss of interaction with the logical implementation. If the proxy admin and logical governance reference the same address, no call will be forwarded to execute the privileged functions, sealing change of governance functionality [[ 1 ]](https://www.certik.com/resources/blog/FnfYrOCsy3MG9s9gixfbJ-upgradeable-proxy-contract-security-best-practices).

#### Defender:

✅ Open Zeppelin Defender is an option as a tool to manage the upgrades and roles of the Allo and Registry cotracts. [Defender v2](https://blog.openzeppelin.com/introducing-openzeppelin-defender-2-0) will offer SAFE support with the ability to [upgrade from a Gnosis SAFE](https://blog.openzeppelin.com/upgrades-app-for-gnosis-safe).

![](https://hackmd.io/_uploads/rywRD_dGa.png)



---

### 💎 Hard Requirements

- [ ] All tests pass 🚨 No Exceptions 🚨

### 🍦 Soft Requirements

- [ ] Completion of all above Hard Requirements

### Upgrade Checklist


#### Updating the Registry Contract Implementation


1. Update the Allo implementaion contract address for each network in the `registry.config.ts` file.
2. Run the following script from the terminal.

```bash
./scripts/core/updateAllNetworks registry
```

3. Update the readme with the new deployed implementation address for the network the contract was upgraded on.

#### Updating the Allo Contract Implementation


1. Update the Allo implementaion contract address for each network in the `allo.config.ts` file.
2. Run the following script from the terminal.

```bash
./scripts/core/updateAllNetworks allo
```

3. Update the readme with the new deployed implementation address for the network the contract was upgraded on.