// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {FlexibleVault} from "../../src/FlexibleVault.sol";
import {MockUSDC} from "../helpers/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FlexibleVaultHandler} from "./FlexibleVaultHandler.sol";

contract FlexibleVaultInvariantsTest is Test {
    FlexibleVault internal vault;
    MockUSDC internal usdc;
    FlexibleVaultHandler internal handler;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    function setUp() public {
        usdc = new MockUSDC(0);
        vault = new FlexibleVault(IERC20(address(usdc)), "Stash Flexible USDC", "svfUSDC");

        // Seed-burn so totalSupply > 0 and totalAssets > 0 before any handler action.
        usdc.mint(address(this), 1e6);
        usdc.approve(address(vault), 1e6);
        vault.deposit(1e6, DEAD);

        handler = new FlexibleVaultHandler(vault, usdc);
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = FlexibleVaultHandler.deposit.selector;
        selectors[1] = FlexibleVaultHandler.withdraw.selector;
        selectors[2] = FlexibleVaultHandler.donate.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    /// @notice The vault's USDC balance must always be >= totalAssets (they should be equal
    ///         since totalAssets is defined as balanceOf(this) in OZ ERC4626; this invariant
    ///         guards against any subclass that overrides differently).
    function invariant_balanceCoversAccounting() public view {
        assertGe(usdc.balanceOf(address(vault)), vault.totalAssets());
    }

    /// @notice After any operation, a 1 USDC deposit must yield > 0 shares. This is the
    ///         first-depositor inflation attack invariant: the classical griefing scenario
    ///         causes 1-USDC deposits to round down to 0 shares; with `_decimalsOffset = 6`
    ///         plus the seed-burn performed in setUp(), this never happens.
    function invariant_inflationAttackFails() public view {
        // previewDeposit(1 USDC) must mint a non-zero amount of shares.
        uint256 shares = vault.previewDeposit(1e6);
        assertGt(shares, 0, "1 USDC deposit must yield > 0 shares under any prior state");
    }

    /// @notice Total share supply is non-zero (seed shares are permanent).
    function invariant_totalSupplyNonZero() public view {
        assertGt(vault.totalSupply(), 0);
    }
}
