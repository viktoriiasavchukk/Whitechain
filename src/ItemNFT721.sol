// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ItemTypes} from "./ItemTypes.sol";

/// @title ItemNFT721
/// @notice ERC721 items. Minting is allowed only by the Crafting contract; burning is allowed only by the Marketplace.
/// @dev Role-gated mint/burn; each token stores its crafted item kind for off-chain metadata rendering.
contract ItemNFT721 is ERC721, AccessControl {
    /// @notice Minter role (held by the Crafting contract).
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Burner role (held by the Marketplace contract).
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Thrown when the provided owner is not the actual token owner.
    /// @param expected The expected owner address.
    /// @param actual The actual owner address.
    error NotTokenOwner(address expected, address actual);

    /// @notice Thrown when querying or acting on a non-existent tokenId.
    /// @param tokenId The unknown token id.
    error UnknownTokenId(uint256 tokenId);

    /// @notice Next token id to be minted (auto-incremented).
    uint256 private _nextTokenId;

    /// @notice Base URI used for token metadata.
    string private _baseUri;

    /// @notice Item kind stored per token id.
    mapping(uint256 => ItemTypes.ItemKind) private _itemKindOf;

    /// @param name_ Collection name.
    /// @param symbol_ Collection symbol.
    /// @param baseUri_ Initial base URI for metadata.
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_
    ) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _baseUri = baseUri_;
        _nextTokenId = 1;
    }

    /// @notice Mint a new item of a given kind to `to`.
    /// @dev Only callable by an address with MINTER_ROLE (e.g., the Crafting contract).
    /// @param to Recipient of the newly minted token.
    /// @param kind Kind of the crafted item to record for this token.
    /// @return tokenId The newly minted ERC721 token id.
    function mintItem(address to, ItemTypes.ItemKind kind)
        external
        onlyRole(MINTER_ROLE)
        returns (uint256 tokenId)
    {
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _itemKindOf[tokenId] = kind;
    }

    /// @notice Burn a token owned by `owner`. Intended to be called by Marketplace.
    /// @dev Only callable by an address with BURNER_ROLE. Reverts if `owner` is not the current owner.
    /// @param owner The current owner who must own `tokenId`.
    /// @param tokenId The token id to burn.
    function burnAuthorized(address owner, uint256 tokenId) external onlyRole(BURNER_ROLE) {
        address actual = _ownerOf(tokenId);
        if (actual == address(0)) revert UnknownTokenId(tokenId);
        if (actual != owner) revert NotTokenOwner(owner, actual);

        _burn(tokenId);
        delete _itemKindOf[tokenId];
    }

    /// @notice Get the item kind for a given token id.
    /// @param tokenId The token id to query.
    /// @return kind The recorded item kind.
    function itemKind(uint256 tokenId) external view returns (ItemTypes.ItemKind kind) {
        if (_ownerOf(tokenId) == address(0)) revert UnknownTokenId(tokenId);
        kind = _itemKindOf[tokenId];
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /// @notice Update the base URI for token metadata.
    /// @param newBase The new base URI string.
    function setBaseURI(string calldata newBase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseUri = newBase;
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}
