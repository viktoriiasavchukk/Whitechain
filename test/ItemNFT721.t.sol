// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {ItemNFT721} from "../src/ItemNFT721.sol";
import {ItemTypes} from "../src/ItemTypes.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract ItemNFT721Test is Test {
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    ItemNFT721 items;
    address admin  = address(0xA11CE);
    address minter = address(0xC0FFEE);
    address burner = address(0xDEAD);
    address alice  = address(0xB0B);

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function setUp() public {
        vm.startPrank(admin);
        items = new ItemNFT721("Items", "ITM", "ipfs://items");
        items.grantRole(MINTER_ROLE, minter);
        items.grantRole(BURNER_ROLE, burner);
        vm.stopPrank();
    }

    function test_constructor_grantsDefaultAdmin() public view {
        assertTrue(items.hasRole(DEFAULT_ADMIN_ROLE, admin));
    }

    function test_setBaseURI_reverts_forNonAdmin() public {
        address nonAdmin = address(0xABCD);
        vm.prank(nonAdmin);
        vm.expectRevert(); // AccessControl: missing DEFAULT_ADMIN_ROLE
        items.setBaseURI("ar://blocked/");
    }

    function test_tokenURI_reflectsBaseURI_updates() public {
        // mint a token first
        vm.prank(minter);
        uint256 id = items.mintItem(alice, ItemTypes.ItemKind.KOZAK_SABRE);
        assertEq(id, 1);

        // set a base URI with a trailing slash so concatenation is correct
        vm.prank(admin);
        items.setBaseURI("ipfs://items/");
        assertEq(items.tokenURI(1), "ipfs://items/1");

        // update again and check it reflects
        vm.prank(admin);
        items.setBaseURI("ar://new-items/");
        assertEq(items.tokenURI(1), "ar://new-items/1");
    }

    function test_mintItem_and_kind() public {
        vm.prank(minter);
        uint256 id = items.mintItem(alice, ItemTypes.ItemKind.ELDER_STAFF);
        assertEq(id, 1);
        assertEq(IERC721(address(items)).ownerOf(1), alice);
        assertEq(uint256(items.itemKind(1)), uint256(ItemTypes.ItemKind.ELDER_STAFF));
    }

    function test_itemKind_reverts_unknown() public {
        vm.expectRevert(abi.encodeWithSelector(ItemNFT721.UnknownTokenId.selector, 999));
        items.itemKind(999);
    }

    function test_burnAuthorized_reverts_wrongOwner_and_unknown() public {
        vm.prank(burner);
        vm.expectRevert(abi.encodeWithSelector(ItemNFT721.UnknownTokenId.selector, 1));
        items.burnAuthorized(alice, 1);

        vm.prank(minter);
        uint256 id = items.mintItem(alice, ItemTypes.ItemKind.KOZAK_SABRE);

        vm.prank(burner);
        vm.expectRevert(abi.encodeWithSelector(ItemNFT721.NotTokenOwner.selector, address(0xBAD), alice));
        items.burnAuthorized(address(0xBAD), id);
    }

    function test_burnAuthorized_ok_and_itemKind_deleted() public {
        vm.prank(minter);
        uint256 id = items.mintItem(alice, ItemTypes.ItemKind.KOZAK_SABRE);

        vm.prank(burner);
        items.burnAuthorized(alice, id);

        vm.expectRevert(); // invalid token ID
        IERC721(address(items)).ownerOf(id);

        vm.expectRevert(abi.encodeWithSelector(ItemNFT721.UnknownTokenId.selector, id));
        items.itemKind(id);
    }

    function test_baseURI_and_supportsInterface() public {
        vm.prank(admin);
        items.setBaseURI("ar://new-items");

        bool ok721 = items.supportsInterface(type(IERC721).interfaceId);
        bool okAC  = items.supportsInterface(type(IAccessControl).interfaceId);
        assertTrue(ok721 && okAC);
    }

    function test_onlyMinterCanMint() public {
        vm.expectRevert();
        items.mintItem(alice, ItemTypes.ItemKind.BATTLE_BRACELET);
    }
}
