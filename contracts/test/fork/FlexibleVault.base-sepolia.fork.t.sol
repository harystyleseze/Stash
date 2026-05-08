// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseSepoliaForkBase} from "../helpers/BaseSepoliaForkBase.sol";
import {FlexibleVault} from "../../src/FlexibleVault.sol";

contract FlexibleVaultBaseSepoliaForkTest is BaseSepoliaForkBase {
    FlexibleVault internal vault;

    function setUp() public {
        if (!_fork()) return;
        _initActors();
        vault = _deploySeedBurnFlexible();
        _giveUsdc(alice, USDC_TEN_THOUSAND);
        _giveUsdc(bob, USDC_TEN_THOUSAND);
        _giveUsdc(attacker, USDC_TEN_THOUSAND * 2);
    }

    function test_BaseSepolia_DepositWithdrawRoundTrip() public onlyWhenForked {
        uint256 amount = USDC_THOUSAND;
        uint256 shares = _approveAndFlexDeposit(vault, alice, amount);
        assertGt(shares, 0);

        uint256 before = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 out = vault.redeem(shares, alice, alice);
        assertEq(usdc.balanceOf(alice) - before, out);
        assertApproxEqAbs(out, amount, 1);
    }

    function test_BaseSepolia_FirstDepositorInflationAttackFails() public onlyWhenForked {
        vm.startPrank(attacker);
        usdc.approve(address(vault), 1);
        vault.deposit(1, attacker);
        usdc.transfer(address(vault), 10_000 * USDC_ONE);
        vm.stopPrank();

        uint256 victimShares = _approveAndFlexDeposit(vault, alice, 5000 * USDC_ONE);
        assertGt(victimShares, 0);
        assertGt(vault.previewRedeem(victimShares), 4900 * USDC_ONE);
    }

    function test_BaseSepolia_MultiUserProportionality() public onlyWhenForked {
        _approveAndFlexDeposit(vault, alice, USDC_HUNDRED);
        _approveAndFlexDeposit(vault, bob, 3 * USDC_HUNDRED);

        assertApproxEqAbs(vault.previewRedeem(vault.balanceOf(alice)), USDC_HUNDRED, 2);
        assertApproxEqAbs(vault.previewRedeem(vault.balanceOf(bob)), 3 * USDC_HUNDRED, 2);
    }
}
