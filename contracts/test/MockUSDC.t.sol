// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockUSDC} from "./helpers/MockUSDC.sol";

/// @dev Dedicated tests for MockUSDC. Without these the `if (initialMint > 0)` branch is
///      otherwise unreachable (the vault-level tests all use `new MockUSDC(0)`).
contract MockUSDCTest is Test {
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function test_DecimalsIsSix() public {
        MockUSDC t = new MockUSDC(0);
        assertEq(t.decimals(), 6);
    }

    function test_NameAndSymbol() public {
        MockUSDC t = new MockUSDC(0);
        assertEq(t.name(), "Mock USD Coin");
        assertEq(t.symbol(), "USDC");
    }

    // --- Constructor branches -----------------------------------------------------------------

    function test_ConstructorWithZeroInitialMintSkipsMint() public {
        MockUSDC t = new MockUSDC(0);
        assertEq(t.totalSupply(), 0);
        assertEq(t.balanceOf(address(this)), 0);
    }

    function test_ConstructorWithPositiveInitialMintMintsToDeployer() public {
        uint256 initial = 1_000_000 * 1e6;
        MockUSDC t = new MockUSDC(initial);
        assertEq(t.totalSupply(), initial);
        assertEq(t.balanceOf(address(this)), initial);
    }

    function test_ConstructorWithOneWeiMints() public {
        MockUSDC t = new MockUSDC(1);
        assertEq(t.totalSupply(), 1);
        assertEq(t.balanceOf(address(this)), 1);
    }

    // --- Faucet mint --------------------------------------------------------------------------

    function test_PublicMintToSelf() public {
        MockUSDC t = new MockUSDC(0);
        vm.prank(alice);
        t.mint(alice, 10 * 1e6);
        assertEq(t.balanceOf(alice), 10 * 1e6);
        assertEq(t.totalSupply(), 10 * 1e6);
    }

    function test_PublicMintToOther() public {
        MockUSDC t = new MockUSDC(0);
        vm.prank(alice);
        t.mint(bob, 5 * 1e6);
        assertEq(t.balanceOf(bob), 5 * 1e6);
        assertEq(t.balanceOf(alice), 0);
    }

    function test_PublicMintZeroAmountSucceeds() public {
        MockUSDC t = new MockUSDC(0);
        t.mint(alice, 0);
        assertEq(t.balanceOf(alice), 0);
        assertEq(t.totalSupply(), 0);
    }

    function test_MintToZeroAddressReverts() public {
        MockUSDC t = new MockUSDC(0);
        vm.expectRevert(); // ERC20InvalidReceiver
        t.mint(address(0), 1e6);
    }

    // --- Fuzz ---------------------------------------------------------------------------------

    function testFuzz_ConstructorMintsInitialSupplyToDeployer(uint128 initial) public {
        MockUSDC t = new MockUSDC(initial);
        assertEq(t.totalSupply(), uint256(initial));
        assertEq(t.balanceOf(address(this)), uint256(initial));
    }

    function testFuzz_PublicMint(address to, uint96 amount) public {
        vm.assume(to != address(0));
        MockUSDC t = new MockUSDC(0);
        uint256 before = t.balanceOf(to);
        t.mint(to, amount);
        assertEq(t.balanceOf(to) - before, amount);
    }
}
