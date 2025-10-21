// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ItemTypes} from "./ItemTypes.sol";

/// @title ResourceNFT1155
/// @notice ERC1155-based resources. Minting and burning are allowed only for authorized contracts (e.g., Crafting, Search, Marketplace).
/// @dev Standard transfers are allowed, but public mint/burn functions are not available.
contract ResourceNFT1155 is ERC1155, AccessControl {
    using Strings for uint256;

    /// @notice Minter role for authorized contracts.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Burner role for authorized contracts.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Base URI for metadata.
    string private _baseUri;

    /// @param baseUri_ Base URI for metadata.
    constructor(string memory baseUri_) ERC1155("") {
        _baseUri = baseUri_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Mint tokens from an authorized contract.
    /// @param to Recipient address.
    /// @param id Resource ID.
    /// @param amount Amount to mint.
    function mintAuthorized(address to, ItemTypes.ResourceId id, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, uint256(id), amount, "");
    }

    /// @notice Batch mint from an authorized contract.
    /// @param to Recipient address.
    /// @param ids Array of resource IDs.
    /// @param amounts Array of amounts corresponding to each resource ID.
    function mintBatchAuthorized(address to, ItemTypes.ResourceId[] calldata ids, uint256[] calldata amounts)
        external
        onlyRole(MINTER_ROLE)
    {
        // Cast `ResourceId` to `uint256` in a loop
        uint256[] memory rawIds = new uint256[](ids.length);
        for(uint256 i=0;i<ids.length;i++) {
            rawIds[i] = uint256(ids[i]);
        }

        _mintBatch(to, rawIds, amounts, "");
    }

    /// @notice Burn tokens from a user by an authorized contract (e.g., during crafting).
    /// @param from Address whose tokens will be burned.
    /// @param id Resource ID.
    /// @param amount Amount to burn.
    function burnAuthorized(address from, ItemTypes.ResourceId id, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, uint256(id), amount);
    }

    /// @notice Batch burn tokens from a user by an authorized contract.
    /// @param from Address whose tokens will be burned.
    /// @param ids Array of resource IDs.
    /// @param amounts Array of amounts corresponding to each resource ID.
    function burnBatchAuthorized(address from, ItemTypes.ResourceId[] calldata ids, uint256[] calldata amounts)
        external
        onlyRole(BURNER_ROLE)
    {
        // Cast `ResourceId` to `uint256` in a loop
        uint256[] memory rawIds = new uint256[](ids.length);
        for(uint256 i=0;i<ids.length;i++) {
            rawIds[i] = uint256(ids[i]);
        }

        _burnBatch(from, rawIds, amounts);
    }

    /// @inheritdoc ERC1155
    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(_baseUri, "/", id.toString(), ".json"));
    }

    /// @notice Update the base URI for metadata.
    /// @param newBase The new base URI.
    function setBaseURI(string calldata newBase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseUri = newBase;
    }

    /// @inheritdoc ERC1155
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}
