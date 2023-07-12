# Voter Module specs

This document outlines specs for **voter** modules, which handle how voters are deemed eligible to vote on a given pool. 

# Specs
## Open eligibility 
In this module, any wallet can cast a vote. 

### Standard functions
- `isValidVoter` — always returns `true`

## Token-gated eligibility 
In this module, any wallet can cast a vote as long as they hold a certain number of a given token. 

### Custom variables
- `requiredToken` — the token that is required to be held by the voter
- `tokenThreshold` — the amount of the `requiredToken` that needs to be in the voter's wallet

### Standard functions
- `isValidVoter` — returns `true` if the voter holds >= `tokenThreshold` of `requiredToken`

## Passport-gated eligibility
In this module, a voter is deemed eligible if they receive a certain Passport score?

### Custom variables
- `????` what do we need to pass to passport to get a return?

## NFT-gated eligibility
In this module, any wallet can cast a vote as long as they hold a specific NFT.

### Custom Variables
- `nftContract` - the NFT that a voter needs to hold to vote

### Standard functions
- `isValidVoter` - returns `true` if the voter holds `nftContract`

## Allowlist
In this module, only the wallets on a given allowlist are allowed to vote. 

### Custom Variables
- `voterAllowlist` - the list of addresses that are allowed to cast a vote

### Standard functions
- `isValidVoter` - returns `true` if the voter is on `voterAllowlist`