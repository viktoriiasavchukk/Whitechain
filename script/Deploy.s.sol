// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {ResourceNFT1155} from "../src/ResourceNFT1155.sol";
import {ItemNFT721}     from "../src/ItemNFT721.sol";
import {MagicToken}     from "../src/MagicToken.sol";
import {CraftingSearch} from "../src/CraftingSearch.sol";
import {ItemTypes}      from "../src/ItemTypes.sol";

/// Deploys all contracts, wires roles, and sets default recipes.
/// Env:
/// - PRIVATE_KEY: deployer private key
/// - RES_BASE_URI (optional, default "ipfs://resources")
/// - ITEMS_NAME   (optional, default "KozakItems")
/// - ITEMS_SYMBOL (optional, default "KOZAK")
/// - ITEMS_BASE   (optional, default "ipfs://items/")
contract Deploy is Script {
    function run() external {
        // ---- env ----
        uint256 pk = vm.envUint("PRIVATE_KEY");
        string memory resBase = vm.envOr("RES_BASE_URI", string("ipfs://resources"));
        string memory itemsName = vm.envOr("ITEMS_NAME", string("KozakItems"));
        string memory itemsSymbol = vm.envOr("ITEMS_SYMBOL", string("KOZAK"));
        string memory itemsBase = vm.envOr("ITEMS_BASE", string("ipfs://items/"));

        vm.startBroadcast(pk);

        // ---- deploy ----
        ResourceNFT1155 resources = new ResourceNFT1155(resBase);
        ItemNFT721 items = new ItemNFT721(itemsName, itemsSymbol, itemsBase);
        MagicToken token = new MagicToken();
        CraftingSearch crafting = new CraftingSearch(resources, items);

        // ---- roles ----
        // Resource1155: Crafting burns; Deployer can mint resources for demos/tests
        resources.grantRole(resources.BURNER_ROLE(), address(crafting));
        resources.grantRole(resources.MINTER_ROLE(), vm.addr(pk));

        // Item721: Crafting mints items
        items.grantRole(items.MINTER_ROLE(), address(crafting));

        // ---- recipes ----
        // Kozak Sabre: 3× IRON + 1× WOOD + 1× LEATHER
        {
            ItemTypes.ResourceId[] memory ids = new ItemTypes.ResourceId[](3);
            uint256[] memory amts = new uint256[](3);
            ids[0] = ItemTypes.ResourceId.IRON;   amts[0] = 3;
            ids[1] = ItemTypes.ResourceId.WOOD;   amts[1] = 1;
            ids[2] = ItemTypes.ResourceId.LEATHER;amts[2] = 1;
            crafting.setRecipe(ItemTypes.ItemKind.KOZAK_SABRE, ids, amts);
        }
        // Elder Staff: 2× WOOD + 1× GOLD + 1× DIAMOND
        {
            ItemTypes.ResourceId[] memory ids = new ItemTypes.ResourceId[](3);
            uint256[] memory amts = new uint256[](3);
            ids[0] = ItemTypes.ResourceId.WOOD;    amts[0] = 2;
            ids[1] = ItemTypes.ResourceId.GOLD;    amts[1] = 1;
            ids[2] = ItemTypes.ResourceId.DIAMOND; amts[2] = 1;
            crafting.setRecipe(ItemTypes.ItemKind.ELDER_STAFF, ids, amts);
        }
        // Armor: 4× LEATHER + 2× IRON + 1× GOLD
        {
            ItemTypes.ResourceId[] memory ids = new ItemTypes.ResourceId[](3);
            uint256[] memory amts = new uint256[](3);
            ids[0] = ItemTypes.ResourceId.LEATHER; amts[0] = 4;
            ids[1] = ItemTypes.ResourceId.IRON;    amts[1] = 2;
            ids[2] = ItemTypes.ResourceId.GOLD;    amts[2] = 1;
            crafting.setRecipe(ItemTypes.ItemKind.KHARAKTERNYK_ARMOR, ids, amts);
        }

        vm.stopBroadcast();

        // ---- output ----
        console2.log("ResourceNFT1155:", address(resources));
        console2.log("ItemNFT721:     ", address(items));
        console2.log("MagicToken:     ", address(token));
        console2.log("CraftingSearch: ", address(crafting));

        console2.log("Deployer/Admin: ", vm.addr(pk));
    }
}
