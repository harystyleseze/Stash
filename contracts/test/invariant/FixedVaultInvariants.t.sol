// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {FixedVault} from "../../src/FixedVault.sol";
import {MockUSDC} from "../helpers/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FixedVaultHandler} from "./FixedVaultHandler.sol";

contract FixedVaultInvariantsTest is Test {
    FixedVault internal vault;
    MockUSDC internal usdc;
    FixedVaultHandler internal handler;

    function setUp() public {
        usdc = new MockUSDC(0);
        vault = new FixedVault(IERC20(address(usdc)));
        handler = new FixedVaultHandler(vault, usdc);

        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = FixedVaultHandler.deposit.selector;
        selectors[1] = FixedVaultHandler.withdraw.selector;
        selectors[2] = FixedVaultHandler.advanceTime.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    /// @notice For every opened position, if it has not been withdrawn and its unlock has not
    ///         yet arrived, the on-chain amount must still equal the amount originally recorded.
    ///         Captures the core promise: locked funds cannot be reduced before maturity.
    function invariant_lockedPositionsAreImmutable() public view {
        uint256 n = handler.openedCount();
        for (uint256 i = 0; i < n; i++) {
            FixedVaultHandler.Ledger memory l = handler.getOpened(i);
            FixedVault.Position memory p = vault.getPosition(l.owner, l.positionId);

            if (!p.withdrawn && block.timestamp < p.unlockAt) {
                assertEq(p.amount, l.recordedAmount, "pre-maturity amount must not change");
                assertEq(p.unlockAt, l.recordedUnlockAt, "unlockAt must not change");
            }
        }
    }

    /// @notice Vault USDC balance must be >= sum of all unwithdrawn positions' recorded amounts.
    function invariant_vaultBalanceCoversAllOpenPositions() public view {
        uint256 n = handler.openedCount();
        uint256 sumOpen = 0;
        for (uint256 i = 0; i < n; i++) {
            FixedVaultHandler.Ledger memory l = handler.getOpened(i);
            FixedVault.Position memory p = vault.getPosition(l.owner, l.positionId);
            if (!p.withdrawn) sumOpen += p.amount;
        }
        assertGe(usdc.balanceOf(address(vault)), sumOpen);
    }
}
