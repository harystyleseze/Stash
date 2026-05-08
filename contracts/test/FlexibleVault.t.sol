// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {TestBase} from "./helpers/TestBase.sol";
import {FlexibleVault} from "../src/FlexibleVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FlexibleVaultTest is TestBase {
    FlexibleVault internal vault;

    function setUp() public {
        _initActors();
        _initUsdc();
        vault = _deploySeedBurnFlexible();
        _giveUsdc(alice, USDC_TEN_THOUSAND);
        _giveUsdc(bob, USDC_TEN_THOUSAND);
        _giveUsdc(attacker, USDC_TEN_THOUSAND * 2);
    }

    function test_AssetIsUSDC() public view {
        assertEq(address(vault.asset()), address(usdc));
    }

    function test_NameAndSymbol() public view {
        assertEq(vault.name(), "Stash Flexible USDC");
        assertEq(vault.symbol(), "svfUSDC");
    }

    function test_DecimalsOffsetIsSix() public view {
        assertEq(vault.decimals(), 12);
    }

    function test_SeedBurnedToDead() public view {
        assertGt(vault.balanceOf(DEAD), 0, "Seed shares must be held by DEAD");
        assertEq(vault.balanceOf(address(this)), 0, "Deployer must hold zero shares after seed-burn");
    }

    function test_TotalAssetsTracksBalance() public {
        assertEq(vault.totalAssets(), usdc.balanceOf(address(vault)));
        _approveAndFlexDeposit(vault, alice, 200 * USDC_ONE);
        assertEq(vault.totalAssets(), usdc.balanceOf(address(vault)));
    }

    function test_DepositMintsShares() public {
        uint256 shares = _approveAndFlexDeposit(vault, alice, USDC_HUNDRED);
        assertGt(shares, 0);
        assertEq(vault.balanceOf(alice), shares);
        assertEq(usdc.balanceOf(address(vault)), USDC_ONE + USDC_HUNDRED);
    }

    function test_WithdrawReturnsAssets() public {
        _approveAndFlexDeposit(vault, alice, USDC_HUNDRED);
        uint256 before = usdc.balanceOf(alice);

        vm.prank(alice);
        vault.withdraw(50 * USDC_ONE, alice, alice);

        assertEq(usdc.balanceOf(alice) - before, 50 * USDC_ONE);
    }

    function test_RedeemReturnsAssets() public {
        uint256 shares = _approveAndFlexDeposit(vault, alice, USDC_HUNDRED);
        uint256 half = shares / 2;

        uint256 before = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 assets = vault.redeem(half, alice, alice);

        assertEq(usdc.balanceOf(alice) - before, assets);
    }

    function test_MintReceivesShares() public {
        uint256 targetShares = 50 * 1e12;
        vm.startPrank(alice);
        usdc.approve(address(vault), type(uint256).max);
        uint256 assetsSpent = vault.mint(targetShares, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), targetShares);
        assertGt(assetsSpent, 0);
    }

    function test_MultipleDepositorsProportionalShares() public {
        _approveAndFlexDeposit(vault, alice, USDC_HUNDRED);
        _approveAndFlexDeposit(vault, bob, 300 * USDC_ONE);

        uint256 a = vault.balanceOf(alice);
        uint256 b = vault.balanceOf(bob);
        assertApproxEqRel(b, a * 3, 0.001e18); // 0.1% tolerance
    }

    function test_ZeroDepositReturnsZeroShares() public {
        vm.startPrank(alice);
        usdc.approve(address(vault), 0);
        uint256 shares = vault.deposit(0, alice);
        vm.stopPrank();
        assertEq(shares, 0);
    }

    function test_RevertDepositWithoutApproval() public {
        // Fresh actor, no approval call at all.
        address dave = makeAddr("dave");
        _giveUsdc(dave, USDC_HUNDRED);
        vm.prank(dave);
        vm.expectRevert(); // ERC20InsufficientAllowance
        vault.deposit(USDC_HUNDRED, dave);
    }

    function test_RevertDepositWithInsufficientBalance() public {
        address dave = makeAddr("dave");
        // Give only 10 USDC but try to deposit 100.
        _giveUsdc(dave, 10 * USDC_ONE);
        vm.startPrank(dave);
        usdc.approve(address(vault), USDC_HUNDRED);
        vm.expectRevert(); // ERC20InsufficientBalance
        vault.deposit(USDC_HUNDRED, dave);
        vm.stopPrank();
    }

    function test_RevertWithdrawMoreThanDeposited() public {
        _approveAndFlexDeposit(vault, alice, USDC_HUNDRED);
        vm.prank(alice);
        vm.expectRevert(); // ERC4626ExceededMaxWithdraw
        vault.withdraw(USDC_THOUSAND, alice, alice);
    }

    function test_RevertWithdrawFromAnotherUserWithoutAllowance() public {
        _approveAndFlexDeposit(vault, alice, USDC_HUNDRED);
        vm.prank(bob);
        vm.expectRevert(); // ERC20InsufficientAllowance on the share token
        vault.withdraw(50 * USDC_ONE, bob, alice);
    }

    function test_RedeemMoreSharesThanOwnedReverts() public {
        uint256 shares = _approveAndFlexDeposit(vault, alice, USDC_HUNDRED);
        vm.prank(alice);
        vm.expectRevert(); // ERC4626ExceededMaxRedeem
        vault.redeem(shares + 1, alice, alice);
    }

    function test_FirstDepositorInflationAttackFails() public {
        vm.startPrank(attacker);
        usdc.approve(address(vault), 1);
        vault.deposit(1, attacker);
        vm.stopPrank();

        // Attacker "donates" 10k USDC directly to inflate `totalAssets`.
        vm.prank(attacker);
        usdc.transfer(address(vault), 10_000 * USDC_ONE);

        uint256 victimShares = _approveAndFlexDeposit(vault, alice, 5000 * USDC_ONE);
        assertGt(victimShares, 0, "victim must receive non-zero shares");

        uint256 redeemable = vault.previewRedeem(victimShares);
        assertGt(redeemable, 4900 * USDC_ONE, "victim must be able to redeem near their full deposit");
    }

    // --- Fuzz --------------------------------------------------------------------------------
    function testFuzz_InflationAttackFailsAtAnyDonationScale(uint96 donation) public {
        donation = uint96(bound(uint256(donation), 1, USDC_TEN_THOUSAND));

        vm.startPrank(attacker);
        usdc.approve(address(vault), 1);
        vault.deposit(1, attacker);
        usdc.transfer(address(vault), donation);
        vm.stopPrank();

        uint256 victimDeposit = USDC_THOUSAND;
        uint256 victimShares = _approveAndFlexDeposit(vault, alice, victimDeposit);
        assertGt(victimShares, 0);

        uint256 redeemable = vault.previewRedeem(victimShares);
        // Allow up to 1% slippage from rounding.
        assertGt(redeemable, (victimDeposit * 99) / 100);
    }

    // Fuzz a deposit → redeem round-trip. Redeeming all shares should return ~deposited assets.
    function testFuzz_DepositRedeemRoundTrip(uint96 amount) public {
        amount = uint96(bound(uint256(amount), 1, USDC_TEN_THOUSAND));
        uint256 shares = _approveAndFlexDeposit(vault, alice, amount);

        uint256 before = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 out = vault.redeem(shares, alice, alice);
        assertEq(usdc.balanceOf(alice) - before, out);
        // Some rounding loss is acceptable but bounded.
        assertApproxEqAbs(out, amount, 1);
    }

    /// @dev Fuzz a deposit → partial withdraw → redeem remainder.
    function testFuzz_DepositPartialWithdrawRedeem(uint96 amount, uint16 pctNum) public {
        amount = uint96(bound(uint256(amount), 100, USDC_TEN_THOUSAND));
        pctNum = uint16(bound(uint256(pctNum), 1, 99));
        uint256 firstOut = (uint256(amount) * pctNum) / 100;

        _approveAndFlexDeposit(vault, alice, amount);

        vm.startPrank(alice);
        vault.withdraw(firstOut, alice, alice);
        uint256 remainingShares = vault.balanceOf(alice);
        uint256 secondOut = vault.redeem(remainingShares, alice, alice);
        vm.stopPrank();

        // Total returned ~= amount (within rounding).
        assertApproxEqAbs(firstOut + secondOut, amount, 2);
    }

    // Fuzz multi-user interleaving. Proportional shares are preserved.
    function testFuzz_TwoDepositorsProportionality(uint96 aDep, uint96 bDep) public {
        aDep = uint96(bound(uint256(aDep), USDC_ONE, USDC_TEN_THOUSAND));
        bDep = uint96(bound(uint256(bDep), USDC_ONE, USDC_TEN_THOUSAND));

        uint256 aShares = _approveAndFlexDeposit(vault, alice, aDep);
        uint256 bShares = _approveAndFlexDeposit(vault, bob, bDep);

        // Bob's share ratio ≈ bDep / aDep of Alice's share ratio (accounting for seed-dilution is bounded).
        // We verify via previewRedeem: preview(aShares) ≈ aDep, preview(bShares) ≈ bDep.
        assertApproxEqAbs(vault.previewRedeem(aShares), aDep, 2);
        assertApproxEqAbs(vault.previewRedeem(bShares), bDep, 2);
    }

    function test_Constructor_RevertWhen_AssetIsZero() public {
        vm.expectRevert(FlexibleVault.ZeroAsset.selector);
        new FlexibleVault(IERC20(address(0)), "Stash Flexible USDC", "svfUSDC");
    }
}
