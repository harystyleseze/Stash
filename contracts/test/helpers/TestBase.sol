// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockUSDC} from "./MockUSDC.sol";
import {FlexibleVault} from "../../src/FlexibleVault.sol";
import {FixedVault} from "../../src/FixedVault.sol";
import {P2PTransfer} from "../../src/P2PTransfer.sol";

/// @dev Shared state + helpers for the Stash test suite. Keeps individual test files focused on
///      scenarios rather than setup boilerplate. Override `_giveUsdc` in a subclass to point at
///      a different funding mechanism (e.g. mainnet-fork whale impersonation).
abstract contract TestBase is Test {
    // --- Actors --------------------------------------------------------------------------------

    address internal alice;
    address internal bob;
    address internal carol;
    address internal attacker;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // --- USDC amount constants (6 decimals) ---------------------------------------------------

    uint256 internal constant USDC_ONE = 1e6;
    uint256 internal constant USDC_HUNDRED = 100 * USDC_ONE;
    uint256 internal constant USDC_THOUSAND = 1000 * USDC_ONE;
    uint256 internal constant USDC_TEN_THOUSAND = 10_000 * USDC_ONE;

    IERC20 internal usdc;

    // --- Setup hooks ---------------------------------------------------------------------------

    /// @dev Call at the start of any concrete test's setUp. Creates four deterministic actors.
    function _initActors() internal {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");
        attacker = makeAddr("attacker");
    }

    /// @dev Deploy a fresh MockUSDC with no initial supply and record it in `usdc`.
    ///      Overridden by the mainnet-fork base to point `usdc` at the real Circle USDC.
    function _initUsdc() internal virtual {
        usdc = IERC20(address(new MockUSDC(0)));
    }

    /// @dev Mint / transfer `amount` USDC to `user`. Overridden for fork tests.
    function _giveUsdc(address user, uint256 amount) internal virtual {
        MockUSDC(address(usdc)).mint(user, amount);
    }

    // --- Deployment helpers --------------------------------------------------------------------

    /// @dev Deploy a FlexibleVault against the current `usdc` and perform the seed-burn from
    ///      the test contract (address(this)). Mirrors what script/Deploy.s.sol does in prod.
    function _deploySeedBurnFlexible() internal returns (FlexibleVault) {
        FlexibleVault v = new FlexibleVault(usdc, "Stash Flexible USDC", "svfUSDC");
        _giveUsdc(address(this), USDC_ONE);
        usdc.approve(address(v), USDC_ONE);
        v.deposit(USDC_ONE, DEAD);
        return v;
    }

    /// @dev Deploy a FixedVault against the current `usdc`.
    function _deployFixed() internal returns (FixedVault) {
        return new FixedVault(usdc);
    }

    /// @dev Deploy a P2PTransfer against the current `usdc`.
    function _deployP2P() internal returns (P2PTransfer) {
        return new P2PTransfer(usdc);
    }

    // --- Action helpers ------------------------------------------------------------------------

    /// @dev One-call approve + deposit into a FlexibleVault from `user`. Returns shares minted.
    function _approveAndFlexDeposit(FlexibleVault v, address user, uint256 amount) internal returns (uint256 shares) {
        vm.startPrank(user);
        usdc.approve(address(v), amount);
        shares = v.deposit(amount, user);
        vm.stopPrank();
    }

    /// @dev One-call approve + lock into a FixedVault from `user`. Returns positionId.
    function _approveAndFixedDeposit(FixedVault v, address user, uint256 amount, uint256 lockSeconds)
        internal
        returns (uint256 positionId)
    {
        vm.startPrank(user);
        usdc.approve(address(v), amount);
        positionId = v.deposit(amount, lockSeconds);
        vm.stopPrank();
    }

    /// @dev One-call approve + send via a P2PTransfer from `user`.
    function _approveAndSend(P2PTransfer p, address user, address to, uint256 amount, string memory memo) internal {
        vm.startPrank(user);
        usdc.approve(address(p), amount);
        p.send(to, amount, memo);
        vm.stopPrank();
    }

    /// @dev Advance chain time by N seconds.
    function _skip(uint256 secondsForward) internal {
        vm.warp(block.timestamp + secondsForward);
    }
}
