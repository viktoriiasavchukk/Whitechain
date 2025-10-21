// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {CraftingSearch} from "../src/CraftingSearch.sol";
import {ResourceNFT1155} from "../src/ResourceNFT1155.sol";
import {ItemNFT721} from "../src/ItemNFT721.sol";
import {ItemTypes} from "../src/ItemTypes.sol";

contract CraftingSearchTest is Test {
    address private admin = address(0xA11CE);
    address private player = address(0xB0B);

    ResourceNFT1155 private resources;
    ItemNFT721 private items;
    CraftingSearch private cs;

    bytes32 private constant MINTER_1155 = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_1155 = keccak256("BURNER_ROLE");
    bytes32 private constant MINTER_721  = keccak256("MINTER_ROLE");

    event Crafted(address indexed player, ItemTypes.ItemKind indexed kind, uint256 tokenId);

    function setUp() public {
        vm.startPrank(admin);
        resources = new ResourceNFT1155("ipfs://res");
        items     = new ItemNFT721("Items", "ITM", "ipfs://items");
        cs        = new CraftingSearch(resources, items);

        // Wire permissions: CraftingSearch can burn 1155 and mint 721.
        resources.grantRole(BURNER_1155, address(cs));
        items.grantRole(MINTER_721, address(cs));

        // Test funding: let admin mint resources to players.
        resources.grantRole(MINTER_1155, admin);
        vm.stopPrank();

        // Fund `player` with the sabre recipe resources: IRON×3, WOOD×1, LEATHER×1
        ItemTypes.ResourceId[] memory ids = new ItemTypes.ResourceId[](3);
        uint256[] memory amts = new uint256[](3);
        ids[0]  = ItemTypes.ResourceId.IRON;
        ids[1]  = ItemTypes.ResourceId.WOOD;
        ids[2]  = ItemTypes.ResourceId.LEATHER;
        amts[0] = 3;
        amts[1] = 1;
        amts[2] = 1;

        vm.prank(admin);
        resources.mintBatchAuthorized(player, ids, amts);
    }

    function test_setRecipe_ok() public {
        ItemTypes.ResourceId[] memory req = new ItemTypes.ResourceId[](3);
        uint256[] memory amt = new uint256[](3);
        req[0] = ItemTypes.ResourceId.IRON;   amt[0] = 3;
        req[1] = ItemTypes.ResourceId.WOOD;   amt[1] = 1;
        req[2] = ItemTypes.ResourceId.LEATHER;amt[2] = 1;

        vm.prank(admin);
        cs.setRecipe(ItemTypes.ItemKind.KOZAK_SABRE, req, amt);
    }

    function test_setRecipe_revert_empty() public {
        ItemTypes.ResourceId[] memory req = new ItemTypes.ResourceId[](0);
        uint256[] memory amt = new uint256[](0);

        vm.prank(admin);
        vm.expectRevert(CraftingSearch.InvalidRecipeEmpty.selector);
        cs.setRecipe(ItemTypes.ItemKind.KOZAK_SABRE, req, amt);
    }

    function test_setRecipe_revert_lenMismatch() public {
        ItemTypes.ResourceId[] memory req = new ItemTypes.ResourceId[](2);
        uint256[] memory amt = new uint256[](1);
        req[0] = ItemTypes.ResourceId.IRON;
        req[1] = ItemTypes.ResourceId.WOOD;
        amt[0] = 3;

        vm.prank(admin);
        vm.expectRevert(CraftingSearch.InvalidRecipeLengthMismatch.selector);
        cs.setRecipe(ItemTypes.ItemKind.KOZAK_SABRE, req, amt);
    }

    function test_craft_revert_noRecipe() public {
        vm.prank(player);
        vm.expectRevert(abi.encodeWithSelector(CraftingSearch.RecipeNotSet.selector, ItemTypes.ItemKind.KOZAK_SABRE));
        cs.craft(ItemTypes.ItemKind.KOZAK_SABRE);
    }

    function test_craft_burns1155_mints721_emits() public {
        // Set sabre recipe
        ItemTypes.ResourceId[] memory req = new ItemTypes.ResourceId[](3);
        uint256[] memory amt = new uint256[](3);
        req[0] = ItemTypes.ResourceId.IRON;   amt[0] = 3;
        req[1] = ItemTypes.ResourceId.WOOD;   amt[1] = 1;
        req[2] = ItemTypes.ResourceId.LEATHER;amt[2] = 1;

        vm.prank(admin);
        cs.setRecipe(ItemTypes.ItemKind.KOZAK_SABRE, req, amt);

        // Pre balances
        assertEq(IERC1155(address(resources)).balanceOf(player, uint256(ItemTypes.ResourceId.IRON)), 3);
        assertEq(IERC1155(address(resources)).balanceOf(player, uint256(ItemTypes.ResourceId.WOOD)), 1);
        assertEq(IERC1155(address(resources)).balanceOf(player, uint256(ItemTypes.ResourceId.LEATHER)), 1);
        assertEq(IERC721(address(items)).balanceOf(player), 0);

        vm.prank(player);
        vm.expectEmit(true, true, false, true);
        emit Crafted(player, ItemTypes.ItemKind.KOZAK_SABRE, 1); // tokenId asserted after call
        uint256 tokenId = cs.craft(ItemTypes.ItemKind.KOZAK_SABRE);
        assertEq(tokenId, 1);

        // Post: resources burned, item minted
        assertEq(IERC1155(address(resources)).balanceOf(player, uint256(ItemTypes.ResourceId.IRON)), 0);
        assertEq(IERC1155(address(resources)).balanceOf(player, uint256(ItemTypes.ResourceId.WOOD)), 0);
        assertEq(IERC1155(address(resources)).balanceOf(player, uint256(ItemTypes.ResourceId.LEATHER)), 0);
        assertEq(IERC721(address(items)).balanceOf(player), 1);
    }
}