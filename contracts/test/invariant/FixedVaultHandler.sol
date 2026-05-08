// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {FixedVault} from "../../src/FixedVault.sol";
import {MockUSDC} from "../helpers/MockUSDC.sol";

contract FixedVaultHandler is Test {
    FixedVault public vault;
    MockUSDC public usdc;
    address[] public actors;

    struct Ledger {
        address owner;
        uint256 positionId;
        uint256 recordedAmount;
        uint64 recordedUnlockAt;
    }

    Ledger[] public openedPositions;

    uint256 public constant USDC_ONE = 1e6;
    uint256 public constant MAX_DEPOSIT = 100_000 * 1e6;

    constructor(FixedVault vault_, MockUSDC usdc_) {
        vault = vault_;
        usdc = usdc_;
        for (uint256 i = 0; i < 5; i++) {
            actors.push(makeAddr(string(abi.encodePacked("fv_actor", vm.toString(i)))));
        }
    }

    function _pickActor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    function _pickLock(uint256 seed) internal view returns (uint256) {
        uint256 r = seed % 3;
        if (r == 0) return vault.LOCK_30_DAYS();
        if (r == 1) return vault.LOCK_60_DAYS();
        return vault.LOCK_90_DAYS();
    }

    function deposit(uint256 amount, uint256 actorSeed, uint256 lockSeed) external {
        amount = bound(amount, 1, MAX_DEPOSIT);
        address actor = _pickActor(actorSeed);
        uint256 lockSeconds = _pickLock(lockSeed);

        usdc.mint(actor, amount);
        vm.startPrank(actor);
        usdc.approve(address(vault), amount);
        uint256 positionId = vault.deposit(amount, lockSeconds);
        vm.stopPrank();

        openedPositions.push(
            Ledger({
                owner: actor,
                positionId: positionId,
                recordedAmount: amount,
                recordedUnlockAt: uint64(block.timestamp + lockSeconds)
            })
        );
    }

    function withdraw(uint256 idx) external {
        if (openedPositions.length == 0) return;
        idx = bound(idx, 0, openedPositions.length - 1);
        Ledger memory l = openedPositions[idx];

        FixedVault.Position memory p = vault.getPosition(l.owner, l.positionId);
        if (p.withdrawn) return;
        if (block.timestamp < p.unlockAt) return;

        vm.prank(l.owner);
        vault.withdraw(l.positionId);
    }

    function advanceTime(uint256 secondsForward) external {
        secondsForward = bound(secondsForward, 1, 30 days);
        vm.warp(block.timestamp + secondsForward);
    }

    function openedCount() external view returns (uint256) {
        return openedPositions.length;
    }

    function getOpened(uint256 idx) external view returns (Ledger memory) {
        return openedPositions[idx];
    }
}
