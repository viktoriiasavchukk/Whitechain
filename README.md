# Козацький бізнес

## Overview
- **ERC1155** `ResourceNFT1155`: base resources — Wood, Iron, Gold, Leather, Stone, Diamond.
- **ERC721** `ItemNFT721`: crafted items — Kozak Sabre, Elder Staff, (optional) Armor.
- **Core** `CraftingSearch`: sets recipes, burns resources, mints items.
- **ERC20** `MagicToken`: reward token (minted by Marketplace).
- **Library** `ItemTypes`: enums for ResourceId / ItemKind.

### Recipes
- **Kozak Sabre:** 3× Iron + 1× Wood + 1× Leather  
- **Elder Staff:** 2× Wood + 1× Gold + 1× Diamond  
- **Armor (optional):** 4× Leather + 2× Iron + 1× Gold

---

## Quick Start
```bash
# deps
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2
forge install foundry-rs/forge-std
npm i   # because deployment scripts are written in Hardhat/Typescript

# tests & coverage
forge test -vv
forge coverage
```

--- 

### Deployed contracts

- ResourceNFT1155: 0x79ED031A5f1d8b405FAA7ea6923810579d08A777
- ItemNFT721:      0xC1cb6777992E1C4640380276a4Eb030b22836520
- MagicToken:      0x674825Df7dfc838285871c2e8Ea5eBfE175EA4c5
- CraftingSearch:  0x0602A601c92A3175561D88babc5E51Ee0c6bfD2d
