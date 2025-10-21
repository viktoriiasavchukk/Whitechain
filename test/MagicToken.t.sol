// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {MagicToken} from "../src/MagicToken.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract MagicTokenTest is Test {
    MagicToken token;
    address admin  = address(0xA11CE);
    address minter = address(0xC0FFEE);
    address user   = address(0xB0B);

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        vm.startPrank(admin);
        token = new MagicToken();
        token.grantRole(MINTER_ROLE, minter);
        vm.stopPrank();
    }

    function test_onlyMinterCanMint() public {
        vm.prank(minter);
        token.mint(user, 1e18);
        assertEq(token.balanceOf(user), 1e18);

        vm.expectRevert();
        token.mint(user, 1);
    }

    function test_supportsInterface_view() public view {
        assertTrue(token.supportsInterface(type(IAccessControl).interfaceId));
    }
}