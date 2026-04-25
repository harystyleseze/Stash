// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deploy} from "../../script/Deploy.s.sol";
import {MockUSDC} from "../helpers/MockUSDC.sol";
import {FlexibleVault} from "../../src/FlexibleVault.sol";
import {FixedVault} from "../../src/FixedVault.sol";
import {P2PTransfer} from "../../src/P2PTransfer.sol";

/// @dev Exercises script/Deploy.s.sol end-to-end. Uses a fresh in-test private key and pre-funds
///      the corresponding deployer address with 1 USDC (required for the seed-burn).
contract DeployScriptTest is Test {
    /// @dev Shared across Deploy.t.sol and DeployMockUSDC.t.sol so concurrent test contracts
    ///      writing PRIVATE_KEY via vm.setEnv never race on *different* values. The consequential
    ///      per-deployer state (balances) is isolated naturally because each test deploys its own
    ///      MockUSDC instance.
    uint256 internal constant TEST_PK = uint256(keccak256("stash.scripts.shared.deployer"));
    address internal deployer;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    function setUp() public {
        deployer = vm.addr(TEST_PK);
    }

    function test_RunDeploysAllThreeContractsAndSeedBurns() public {
        // Deploy a MockUSDC and fund the deployer for the seed-burn.
        MockUSDC usdc = new MockUSDC(0);
        usdc.mint(deployer, 1e6);

        vm.setEnv("PRIVATE_KEY", vm.toString(TEST_PK));
        vm.setEnv("USDC_ADDRESS", vm.toString(address(usdc)));

        Deploy deploy = new Deploy();
        (FlexibleVault flex, FixedVault fix, P2PTransfer p2p) = deploy.run();

        // All addresses non-zero.
        assertTrue(address(flex) != address(0), "flex");
        assertTrue(address(fix) != address(0), "fixed");
        assertTrue(address(p2p) != address(0), "p2p");

        // All wired to the same underlying asset.
        assertEq(address(flex.asset()), address(usdc));
        assertEq(address(fix.asset()), address(usdc));
        assertEq(address(p2p.asset()), address(usdc));

        // Seed-burn landed in DEAD.
        assertGt(flex.balanceOf(DEAD), 0);
        assertEq(flex.totalAssets(), 1e6);
        // Deployer holds no shares.
        assertEq(flex.balanceOf(deployer), 0);
        // Deployer's USDC went into the vault (no longer held by deployer).
        assertEq(usdc.balanceOf(deployer), 0);
    }

    function test_RunRevertsWhenUsdcAddressIsZero() public {
        usdc_reset_env(address(0));

        Deploy deploy = new Deploy();
        vm.expectRevert(bytes("USDC_ADDRESS must not be zero"));
        deploy.run();
    }

    function test_RunRevertsWhenDeployerHoldsLessThanOneUsdc() public {
        MockUSDC usdc = new MockUSDC(0);
        // Give deployer only 0.5 USDC (insufficient for the 1 USDC seed-burn).
        usdc.mint(deployer, 500_000);

        vm.setEnv("PRIVATE_KEY", vm.toString(TEST_PK));
        vm.setEnv("USDC_ADDRESS", vm.toString(address(usdc)));

        Deploy deploy = new Deploy();
        vm.expectRevert(bytes("Deployer must hold at least 1 USDC for seed-burn"));
        deploy.run();
    }

    // --- Helpers ------------------------------------------------------------------------------

    function usdc_reset_env(address usdcAddr) internal {
        vm.setEnv("PRIVATE_KEY", vm.toString(TEST_PK));
        vm.setEnv("USDC_ADDRESS", vm.toString(usdcAddr));
    }
}
