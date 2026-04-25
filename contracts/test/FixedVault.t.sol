// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {TestBase} from "./helpers/TestBase.sol";
import {FixedVault} from "../src/FixedVault.sol";

/// @dev Unit + fuzz tests for FixedVault against MockUSDC.
///      Fork equivalent lives in test/fork/FixedVault.fork.t.sol.
contract FixedVaultTest is TestBase {
    FixedVault internal vault;
    uint256 internal lock30;
    uint256 internal lock60;
    uint256 internal lock90;

    function setUp() public {
        _initActors();
        _initUsdc();
        vault = _deployFixed();
        lock30 = vault.LOCK_30_DAYS();
        lock60 = vault.LOCK_60_DAYS();
        lock90 = vault.LOCK_90_DAYS();

        _giveUsdc(alice, USDC_TEN_THOUSAND);
        _giveUsdc(bob, USDC_TEN_THOUSAND);
    }

    // --- Wiring --------------------------------------------------------------------------------

    function test_AssetIsUSDC() public view {
        assertEq(address(vault.asset()), address(usdc));
    }

    function test_LockConstants() public view {
        assertEq(lock30, 30 days);
        assertEq(lock60, 60 days);
        assertEq(lock90, 90 days);
    }

    // --- Deposit happy path --------------------------------------------------------------------

    function test_Deposit30DaysRecordsPosition() public {
        uint256 id = _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);

        assertEq(id, 0);
        FixedVault.Position memory p = vault.getPosition(alice, 0);
        assertEq(p.amount, USDC_HUNDRED);
        assertEq(p.unlockAt, block.timestamp + 30 days);
        assertEq(p.withdrawn, false);

        assertEq(usdc.balanceOf(address(vault)), USDC_HUNDRED);
    }

    function test_Deposit60DaysRecordsPosition() public {
        _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock60);
        assertEq(vault.getPosition(alice, 0).unlockAt, block.timestamp + 60 days);
    }

    function test_Deposit90DaysRecordsPosition() public {
        _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock90);
        assertEq(vault.getPosition(alice, 0).unlockAt, block.timestamp + 90 days);
    }

    function test_DepositEmitsPositionOpened() public {
        vm.startPrank(alice);
        usdc.approve(address(vault), USDC_HUNDRED);
        vm.expectEmit(true, true, false, true, address(vault));
        emit FixedVault.PositionOpened(alice, 0, USDC_HUNDRED, uint64(block.timestamp + 30 days));
        vault.deposit(USDC_HUNDRED, lock30);
        vm.stopPrank();
    }

    // --- Deposit failure flows ----------------------------------------------------------------

    function test_RevertDepositZeroAmount() public {
        vm.startPrank(alice);
        vm.expectRevert(FixedVault.ZeroAmount.selector);
        vault.deposit(0, lock30);
        vm.stopPrank();
    }

    function test_RevertDepositAmountExceedsUint128() public {
        uint256 huge = uint256(type(uint128).max) + 1;
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(FixedVault.AmountTooLarge.selector, huge));
        vault.deposit(huge, lock30);
        vm.stopPrank();
    }

    function test_RevertDepositAtUint128BoundaryMinusOne() public {
        // Right at the allowed boundary: uint128 max is fine (accounting-wise) if user has allowance + balance.
        // We don't give that much USDC, so this reverts on insufficient balance. Boundary behaviour
        // verified by the next test.
        uint256 max = type(uint128).max;
        vm.startPrank(alice);
        usdc.approve(address(vault), max);
        vm.expectRevert(); // ERC20InsufficientBalance (alice doesn't have 2^128 USDC)
        vault.deposit(max, lock30);
        vm.stopPrank();
    }

    function test_RevertInvalidLockDurations() public {
        uint256[6] memory bad = [uint256(0), 1 days, 15 days, 31 days, 45 days, 120 days];
        for (uint256 i = 0; i < bad.length; i++) {
            vm.startPrank(alice);
            vm.expectRevert(abi.encodeWithSelector(FixedVault.InvalidLockDuration.selector, bad[i]));
            vault.deposit(USDC_HUNDRED, bad[i]);
            vm.stopPrank();
        }
    }

    function test_RevertDepositWithoutApproval() public {
        vm.startPrank(alice);
        // No approve.
        vm.expectRevert(); // ERC20InsufficientAllowance
        vault.deposit(USDC_HUNDRED, lock30);
        vm.stopPrank();
    }

    function test_RevertDepositWithInsufficientBalance() public {
        address dave = makeAddr("dave");
        _giveUsdc(dave, 10 * USDC_ONE);

        vm.startPrank(dave);
        usdc.approve(address(vault), USDC_HUNDRED);
        vm.expectRevert(); // ERC20InsufficientBalance
        vault.deposit(USDC_HUNDRED, lock30);
        vm.stopPrank();
    }

    // --- Withdraw happy path ------------------------------------------------------------------

    function test_WithdrawExactlyAtUnlockSucceeds() public {
        uint256 id = _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);
        uint64 unlockAt = vault.getPosition(alice, id).unlockAt;
        vm.warp(unlockAt);

        uint256 before = usdc.balanceOf(alice);
        vm.prank(alice);
        vault.withdraw(id);
        assertEq(usdc.balanceOf(alice) - before, USDC_HUNDRED);
        assertTrue(vault.getPosition(alice, id).withdrawn);
    }

    function test_WithdrawAfterUnlockSucceeds() public {
        uint256 id = _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock90);
        _skip(91 days);

        uint256 before = usdc.balanceOf(alice);
        vm.prank(alice);
        vault.withdraw(id);
        assertEq(usdc.balanceOf(alice) - before, USDC_HUNDRED);
    }

    function test_WithdrawEmitsPositionClosed() public {
        uint256 id = _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);
        _skip(31 days);

        vm.expectEmit(true, true, false, true, address(vault));
        emit FixedVault.PositionClosed(alice, id, USDC_HUNDRED);
        vm.prank(alice);
        vault.withdraw(id);
    }

    // --- Withdraw failure flows ---------------------------------------------------------------

    function test_RevertWithdrawBeforeUnlock() public {
        uint256 id = _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);
        uint64 unlockAt = vault.getPosition(alice, id).unlockAt;
        vm.warp(unlockAt - 1);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FixedVault.NotYetUnlocked.selector, unlockAt));
        vault.withdraw(id);
    }

    function test_RevertDoubleWithdraw() public {
        uint256 id = _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);
        _skip(31 days);
        vm.prank(alice);
        vault.withdraw(id);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FixedVault.AlreadyWithdrawn.selector, id));
        vault.withdraw(id);
    }

    function test_RevertWithdrawNonexistentPosition() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FixedVault.PositionNotFound.selector, 0));
        vault.withdraw(0);
    }

    function test_RevertWithdrawPositionIdBeyondArrayLength() public {
        _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);
        // Alice has id=0; ids 1..N-1 don't exist.
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FixedVault.PositionNotFound.selector, 99));
        vault.withdraw(99);
    }

    // --- View functions (close remaining branches) -------------------------------------------

    function test_GetPositionOutOfBoundsReverts() public {
        // Missing-branch coverage: `getPosition` should revert when positionId >= length.
        vm.expectRevert(abi.encodeWithSelector(FixedVault.PositionNotFound.selector, 0));
        vault.getPosition(alice, 0);

        // Even after alice has one position, querying id=1 reverts.
        _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);
        vm.expectRevert(abi.encodeWithSelector(FixedVault.PositionNotFound.selector, 1));
        vault.getPosition(alice, 1);
    }

    function test_GetPositionsEmptyForFreshUser() public view {
        FixedVault.Position[] memory positions = vault.getPositions(alice);
        assertEq(positions.length, 0);
    }

    function test_PositionCountStartsAtZero() public view {
        assertEq(vault.positionCount(alice), 0);
    }

    function test_TotalLockedStartsAtZero() public view {
        assertEq(vault.totalLocked(), 0);
    }

    function test_TotalLockedTracksBalance() public {
        _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);
        assertEq(vault.totalLocked(), USDC_HUNDRED);

        _approveAndFixedDeposit(vault, bob, 2 * USDC_HUNDRED, lock60);
        assertEq(vault.totalLocked(), 3 * USDC_HUNDRED);
    }

    // --- Multi-position -----------------------------------------------------------------------

    function test_MultiplePositionsPerUser() public {
        vm.startPrank(alice);
        usdc.approve(address(vault), 6 * USDC_HUNDRED);
        vault.deposit(USDC_HUNDRED, lock30);
        vault.deposit(2 * USDC_HUNDRED, lock60);
        vault.deposit(3 * USDC_HUNDRED, lock90);
        vm.stopPrank();

        FixedVault.Position[] memory all = vault.getPositions(alice);
        assertEq(all.length, 3);
        assertEq(all[0].amount, USDC_HUNDRED);
        assertEq(all[1].amount, 2 * USDC_HUNDRED);
        assertEq(all[2].amount, 3 * USDC_HUNDRED);
        assertEq(all[0].unlockAt, block.timestamp + 30 days);
        assertEq(all[1].unlockAt, block.timestamp + 60 days);
        assertEq(all[2].unlockAt, block.timestamp + 90 days);

        _skip(31 days);
        uint256 before = usdc.balanceOf(alice);
        vm.prank(alice);
        vault.withdraw(0);
        assertEq(usdc.balanceOf(alice) - before, USDC_HUNDRED);
        assertTrue(vault.getPosition(alice, 0).withdrawn);
        assertFalse(vault.getPosition(alice, 1).withdrawn);
        assertFalse(vault.getPosition(alice, 2).withdrawn);
    }

    function test_PositionsIndependentAcrossUsers() public {
        _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);
        _approveAndFixedDeposit(vault, bob, 2 * USDC_HUNDRED, lock30);

        assertEq(vault.positionCount(alice), 1);
        assertEq(vault.positionCount(bob), 1);
        assertEq(vault.getPosition(alice, 0).amount, USDC_HUNDRED);
        assertEq(vault.getPosition(bob, 0).amount, 2 * USDC_HUNDRED);
    }

    // --- Fuzz ---------------------------------------------------------------------------------

    function testFuzz_DepositAndWithdraw(uint96 amount, uint8 lockChoice) public {
        vm.assume(amount > 0);

        uint256 dur;
        uint256 r = lockChoice % 3;
        if (r == 0) dur = lock30;
        else if (r == 1) dur = lock60;
        else dur = lock90;

        _giveUsdc(alice, amount);
        vm.startPrank(alice);
        usdc.approve(address(vault), amount);
        uint256 id = vault.deposit(amount, dur);
        vm.stopPrank();

        // Must revert before maturity.
        vm.prank(alice);
        vm.expectRevert();
        vault.withdraw(id);

        _skip(dur + 1);
        uint256 before = usdc.balanceOf(alice);
        vm.prank(alice);
        vault.withdraw(id);
        assertEq(usdc.balanceOf(alice) - before, amount);
    }

    /// @dev Fuzz many positions from the same user, ensuring each is independently correct.
    function testFuzz_ManyPositionsFromOneUser(uint8 count, uint96 perPosition) public {
        count = uint8(bound(uint256(count), 1, 10));
        perPosition = uint96(bound(uint256(perPosition), 1, USDC_HUNDRED));

        uint256 total = uint256(perPosition) * count;
        _giveUsdc(alice, total);
        vm.startPrank(alice);
        usdc.approve(address(vault), total);
        for (uint256 i = 0; i < count; i++) {
            vault.deposit(perPosition, lock30);
        }
        vm.stopPrank();

        assertEq(vault.positionCount(alice), count);
        _skip(31 days);

        uint256 before = usdc.balanceOf(alice);
        for (uint256 i = 0; i < count; i++) {
            vm.prank(alice);
            vault.withdraw(i);
        }
        assertEq(usdc.balanceOf(alice) - before, total);
    }

    /// @dev Fuzz: withdrawing at any timestamp strictly before unlockAt must revert.
    function testFuzz_WithdrawBeforeAnyTimestampReverts(uint64 early) public {
        uint256 id = _approveAndFixedDeposit(vault, alice, USDC_HUNDRED, lock30);
        uint64 unlockAt = vault.getPosition(alice, id).unlockAt;
        early = uint64(bound(uint256(early), block.timestamp, uint256(unlockAt) - 1));

        vm.warp(early);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(FixedVault.NotYetUnlocked.selector, unlockAt));
        vault.withdraw(id);
    }
}
