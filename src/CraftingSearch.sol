// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ResourceNFT1155} from "./ResourceNFT1155.sol";
import {ItemNFT721} from "./ItemNFT721.sol";
import {ItemTypes} from "./ItemTypes.sol";

/// @title Crafting & Search
/// @notice Single entry point for the resource search and item crafting flows.
/// @dev Uses role-based access control for admin actions; mint/burn is delegated to ERC1155/721 contracts.
contract CraftingSearch is AccessControl {
    using ItemTypes for ItemTypes.ResourceId;

    /// @notice Thrown when recipe arrays have different lengths.
    error InvalidRecipeLengthMismatch();
    /// @notice Thrown when recipe arrays are empty.
    error InvalidRecipeEmpty();
    /// @notice Thrown when a recipe for the given item kind is not configured.
    error RecipeNotSet(ItemTypes.ItemKind kind);
    /// @notice Thrown when the player does not have enough of a required resource.
    error InsufficientResourceBalance(address account, uint256 resourceId, uint256 required, uint256 available);

    /// @notice Emitted after a search (exactly 3 resources discovered).
    /// @param player The player who performed the search.
    /// @param resourceIds The three discovered resource IDs.
    event Searched(address indexed player, uint256[3] resourceIds);

    /// @notice Emitted after a successful craft.
    /// @param player The player who crafted the item.
    /// @param kind The kind of item crafted.
    /// @param tokenId The ERC721 token ID of the crafted item.
    event Crafted(address indexed player, ItemTypes.ItemKind indexed kind, uint256 tokenId);

    /// @notice ERC1155 resources contract.
    ResourceNFT1155 public immutable resources;
    /// @notice ERC721 items contract.
    ItemNFT721 public immutable items;

    /// @notice Crafting recipe descriptor.
    struct Recipe {
        ItemTypes.ResourceId[] resourceIds; // Resource IDs required (ERC1155)
        uint256[] amountsRequired;          // Corresponding required amounts
        ItemTypes.ItemKind itemKind;        // Crafted item kind (ERC721)
    }

    /// @notice Mapping of item kind to its crafting recipe.
    mapping(ItemTypes.ItemKind => Recipe) private _recipes;

    /// @param res Address of the ResourceNFT1155 contract.
    /// @param it Address of the ItemNFT721 contract.
    constructor(ResourceNFT1155 res, ItemNFT721 it) {
        resources = res;
        items = it;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Configure or update a crafting recipe for a given item kind.
    /// @dev Both arrays must be non-empty and of equal length.
    /// @param kind Item kind to configure.
    /// @param resourceIds Array of required ERC1155 resource IDs.
    /// @param amountsRequired Array of required amounts, matched by index to `resourceIds`.
    function setRecipe(
        ItemTypes.ItemKind kind,
        ItemTypes.ResourceId[] calldata resourceIds,
        uint256[] calldata amountsRequired
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (resourceIds.length != amountsRequired.length) revert InvalidRecipeLengthMismatch();
        if (resourceIds.length == 0) revert InvalidRecipeEmpty();

        _recipes[kind] = Recipe({
            resourceIds: resourceIds,
            amountsRequired: amountsRequired,
            itemKind: kind
        });
    }

    /// @notice Craft an item according to its configured recipe (required resources will be burned).
    /// @param kind The item kind to craft.
    /// @return tokenId The ERC721 token ID of the newly minted item.
    function craft(ItemTypes.ItemKind kind) external returns (uint256 tokenId) {
        Recipe storage rc = _recipes[kind];
        uint256 len = rc.resourceIds.length;
        if (len == 0) revert RecipeNotSet(kind);

        // Burn required resources and mint the crafted item
        resources.burnBatchAuthorized(msg.sender, rc.resourceIds, rc.amountsRequired);
        tokenId = items.mintItem(msg.sender, kind);

        emit Crafted(msg.sender, kind, tokenId);
    }
}
