// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title  Mock USDC
/// @notice 6-decimal ERC-20 used as a test fixture for unit + fuzz tests. Stash deploys against
///         the real Circle-native USDC on Base Sepolia (0x036CbD5...cF7e) and Base mainnet
///         (0x833589...a02913); this mock is never deployed to a live chain.
/// @dev    Test-only. Located under test/helpers/ (outside src/) so it cannot accidentally be
///         broadcast from the deploy script. Freely-mintable via `mint()` for test convenience.
contract MockUSDC is ERC20 {
    constructor(uint256 initialMint) ERC20("Mock USD Coin", "USDC") {
        if (initialMint > 0) {
            _mint(msg.sender, initialMint);
        }
    }

    /// @dev USDC has 6 decimals.
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @notice Testnet faucet: anyone can mint themselves test USDC. Do not use in production.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
