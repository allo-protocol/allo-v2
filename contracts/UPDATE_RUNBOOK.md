## Contract Updates Runbook

### 💎 Hard Requirements

- [ ] All tests pass 🚨 No Exceptions 🚨

### 🍦 Soft Requirements

- [ ] Completion of all above Hard Requirements

### Upgrade Checklist

<!-- TODO: run through with team how we would update the contracts (an example) -->

#### For updating the Registry Contract

<!-- TODO: -->

#### ⤴️ For updating the Allo Contract Implementation

📝 The following example shows how to upgrade the Allo contract implementation on the sepolia network.

1. Update the Allo contract in the `allo.config.ts` file.

```bash
npx hardhat run scripts/upgradeAllo.ts --network sepolia
```

2. Update the Allo contract implementation in the `allo.config.ts` file.
3. Update the readme with the new deployed implementation address for the network the contract was upgraded on.
