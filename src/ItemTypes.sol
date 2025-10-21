// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

/// @title Item & Resource Types
/// @notice Common enums/constants for the game.
library ItemTypes {
    /// @notice ERC1155 Resource IDs
    enum ResourceId { NONE, WOOD, IRON, GOLD, LEATHER, STONE, DIAMOND }

    /// @notice Crafted ERC721 items
    enum ItemKind { NONE, KOZAK_SABRE, ELDER_STAFF, KHARAKTERNYK_ARMOR, BATTLE_BRACELET }
}
