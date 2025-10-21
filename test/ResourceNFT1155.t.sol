// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {ResourceNFT1155} from "../src/ResourceNFT1155.sol";
import {ItemTypes} from "../src/ItemTypes.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract ResourceNFT1155Test is Test {
    ResourceNFT1155 res;
    address admin = address(0xA11CE);
    address user  = address(0xB0B);

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function setUp() public {
        vm.startPrank(admin);
        res = new ResourceNFT1155("ipfs://base");
        res.grantRole(MINTER_ROLE, admin);
        res.grantRole(BURNER_ROLE, admin);
        vm.stopPrank();
    }

    function test_mint_and_burn_single() public {
        vm.prank(admin);
        res.mintAuthorized(user, ItemTypes.ResourceId.GOLD, 5);
        assertEq(IERC1155(address(res)).balanceOf(user, uint256(ItemTypes.ResourceId.GOLD)), 5);

        vm.prank(admin);
        res.burnAuthorized(user, ItemTypes.ResourceId.GOLD, 3);
        assertEq(IERC1155(address(res)).balanceOf(user, uint256(ItemTypes.ResourceId.GOLD)), 2);
    }

    function test_mintBatch_and_burnBatch() public {
        ItemTypes.ResourceId[] memory ids = new ItemTypes.ResourceId[](2);
        uint256[] memory amts = new uint256[](2);
        ids[0]  = ItemTypes.ResourceId.WOOD;  amts[0] = 7;
        ids[1]  = ItemTypes.ResourceId.STONE; amts[1] = 9;

        vm.prank(admin);
        res.mintBatchAuthorized(user, ids, amts);
        assertEq(IERC1155(address(res)).balanceOf(user, uint256(ids[0])), 7);
        assertEq(IERC1155(address(res)).balanceOf(user, uint256(ids[1])), 9);

        ItemTypes.ResourceId[] memory rids = new ItemTypes.ResourceId[](2);
        uint256[] memory burns = new uint256[](2);
        rids[0] = ItemTypes.ResourceId.WOOD;  burns[0] = 5;
        rids[1] = ItemTypes.ResourceId.STONE; burns[1] = 4;

        vm.prank(admin);
        res.burnBatchAuthorized(user, rids, burns);
        assertEq(IERC1155(address(res)).balanceOf(user, uint256(ids[0])), 2);
        assertEq(IERC1155(address(res)).balanceOf(user, uint256(ids[1])), 5);
    }

    function test_revert_when_not_minter_or_burner() public {
        vm.expectRevert();
        res.mintAuthorized(user, ItemTypes.ResourceId.IRON, 1);

        vm.expectRevert();
        res.burnAuthorized(user, ItemTypes.ResourceId.WOOD, 1);

        ItemTypes.ResourceId[] memory r = new ItemTypes.ResourceId[](1);
        uint256[] memory a = new uint256[](1);
        r[0] = ItemTypes.ResourceId.WOOD; a[0] = 1;

        vm.expectRevert();
        res.burnBatchAuthorized(user, r, a);
    }

    function test_uri_and_setBaseURI() public {
        assertEq(res.uri(uint256(ItemTypes.ResourceId.DIAMOND)), "ipfs://base/6.json");
        vm.prank(admin);
        res.setBaseURI("ar://new");
        assertEq(res.uri(uint256(ItemTypes.ResourceId.DIAMOND)), "ar://new/6.json");
    }

    function test_supportsInterface_view() public view {
        bool ok1155 = res.supportsInterface(type(IERC1155).interfaceId);
        bool okAC   = res.supportsInterface(type(IAccessControl).interfaceId);
        assert(ok1155 && okAC);
    }
}
