// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {FlexibleVault} from "../../src/FlexibleVault.sol";
import {MockUSDC} from "../helpers/MockUSDC.sol";

// Handler for FlexibleVault invariant tests. Constrained random-op surface.
contract FlexibleVaultHandler is Test {
    FlexibleVault public vault;
    MockUSDC public usdc;
    address[] public actors;

    uint256 public constant USDC_ONE = 1e6;
    uint256 public constant MAX_DEPOSIT = 1_000_000 * 1e6; // 1M USDC per deposit

    constructor(FlexibleVault vault_, MockUSDC usdc_) {
        vault = vault_;
        usdc = usdc_;
        for (uint256 i = 0; i < 5; i++) {
            address actor = makeAddr(string(abi.encodePacked("actor", vm.toString(i))));
            actors.push(actor);
        }
    }

    function _pickActor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    function deposit(uint256 amount, uint256 actorSeed) external {
        amount = bound(amount, 1, MAX_DEPOSIT);
        address actor = _pickActor(actorSeed);
        usdc.mint(actor, amount);

        vm.startPrank(actor);
        usdc.approve(address(vault), amount);
        vault.deposit(amount, actor);
        vm.stopPrank();
    }

    function withdraw(uint256 assets, uint256 actorSeed) external {
        address actor = _pickActor(actorSeed);
        uint256 max = vault.maxWithdraw(actor);
        if (max == 0) return;
        assets = bound(assets, 1, max);

        vm.prank(actor);
        vault.withdraw(assets, actor, actor);
    }

    function donate(uint256 amount, uint256 actorSeed) external {
        // Direct donation attack attempt.
        amount = bound(amount, 1, MAX_DEPOSIT);
        address actor = _pickActor(actorSeed);
        usdc.mint(actor, amount);
        vm.prank(actor);
        usdc.transfer(address(vault), amount);
    }

    function actorCount() external view returns (uint256) {
        return actors.length;
    }
}
