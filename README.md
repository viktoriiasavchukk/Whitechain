# Козацький бізнес

## Overview

`ResourceNFT1155` contract is responsible for managing the resource NFTs (e.g., Wood, Iron, Gold, etc.). The contract inherits OpenZeppelin’s `AccessControl` for managing the roles of admin, minter, and burner. The admin can grant/remove the minter role, while the minter can mint new resources for a specified address and the burner can burn them. 

`ItemNFT721` is responsible for managing item NFTs and has the same set of roles and similar functionality. The only difference is that it works with unique NFT items rather than resources that may have multiple units. Each item NFT has a unique ID.

`CraftingSearch` is a contract that manages the recipes from resource NFTs to item NFTs. I also use the `AccessControl` contract to restrict setting new recipes to the admin only. The recipes are not hardcoded and can be changed “on the fly.” Anyone can call the contract to burn the required amount of resource NFTs to mint the new item NFT.

`MagicToken` is an unfinished contract for the 4th task.

The code has 100% coverage and the contracts are deployed on Whitechain testnet.

### Default Recipes

The default deploy scripts add those recipes:

- **Kozak Sabre:** 3× Iron + 1× Wood + 1× Leather  
- **Elder Staff:** 2× Wood + 1× Gold + 1× Diamond  
- **Armor:** 4× Leather + 2× Iron + 1× Gold

---

## Quick Start
```bash
# deps
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2
forge install foundry-rs/forge-std

# tests & coverage
forge test -vv
forge coverage --skip ".s.sol"
```

--- 

### Deployed contracts on Whitechain testnet

- ResourceNFT1155: 0x79ED031A5f1d8b405FAA7ea6923810579d08A777
- ItemNFT721:      0xC1cb6777992E1C4640380276a4Eb030b22836520
- CraftingSearch:  0x0602A601c92A3175561D88babc5E51Ee0c6bfD2d
- MagicToken:      0x674825Df7dfc838285871c2e8Ea5eBfE175EA4c5
