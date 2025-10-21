// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title MagicToken (ERC20)
/// @notice Reward token used within the ecosystem. Minting is restricted exclusively to the Marketplace contract.
/// @dev Standard ERC20 token with role-based minting control (MINTER_ROLE).
contract MagicToken is ERC20, AccessControl {
    /// @notice Minter role (assigned to the Marketplace contract).
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Thrown when the caller does not have the MINTER_ROLE.
    /// @param caller The address that attempted to mint without permission.
    error UnauthorizedMinter(address caller);

    /// @notice Deploys the MagicToken contract and assigns the deployer as the default admin.
    constructor() ERC20("MagicToken", "MAGIC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Mint new tokens to the specified address.
    /// @dev Only callable by an address with the MINTER_ROLE (e.g., Marketplace).
    /// @param to The recipient address that will receive the newly minted tokens.
    /// @param amount The number of tokens to mint.
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
