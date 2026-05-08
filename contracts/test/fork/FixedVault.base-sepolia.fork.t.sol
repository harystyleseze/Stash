// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseSepoliaForkBase} from "../helpers/BaseSepoliaForkBase.sol";
import {FixedVault} from "../../src/FixedVault.sol";

// Fork tests for FixedVault against real Circle-native USDC on Base Sepolia.
contract FixedVaultBaseSepoliaForkTest is BaseSepoliaForkBase {
    FixedVault internal vault;

    function setUp() public {
        if (!_fork()) return;
        _initActors();
        vault = _deployFixed();
        _giveUsdc(alice, 1000 * USDC_ONE);
    }

    function test_BaseSepolia_LockAndWithdraw() public onlyWhenForked {
        uint256 id = _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, vault.LOCK_30_DAYS());

        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(id);

        _skip(31 days);

        uint256 before = usdc.balanceOf(alice);
        vm.prank(alice);
        vault.withdraw(id);
        assertEq(usdc.balanceOf(alice) - before, USDC_HUNDRED);
        assertTrue(vault.getPosition(alice, id).withdrawn);
    }

    function test_BaseSepolia_ThreeDurationsCoexist() public onlyWhenForked {
        uint256 id30 = _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, vault.LOCK_30_DAYS());
        uint256 id60 = _approveAndFixedDeposit(vault, alice, 2 * USDC_HUNDRED, vault.LOCK_60_DAYS());
        uint256 id90 = _approveAndFixedDeposit(vault, alice, 3 * USDC_HUNDRED, vault.LOCK_90_DAYS());

        _skip(31 days);
        vm.prank(alice);
        vault.withdraw(id30);
        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(id60);

        _skip(30 days);
        vm.prank(alice);
        vault.withdraw(id60);
        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(id90);

        _skip(30 days);
        vm.prank(alice);
        vault.withdraw(id90);

        assertEq(vault.totalLocked(), 0);
    }
}
