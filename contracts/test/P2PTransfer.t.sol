// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {TestBase} from "./helpers/TestBase.sol";
import {P2PTransfer} from "../src/P2PTransfer.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Unit + fuzz tests for P2PTransfer against MockUSDC.
contract P2PTransferTest is TestBase {
    P2PTransfer internal p2p;

    function setUp() public {
        _initActors();
        _initUsdc();
        p2p = _deployP2P();
        _giveUsdc(alice, USDC_THOUSAND);
    }

    // --- Happy path ---------------------------------------------------------------------------

    function test_SendMovesAssets() public {
        _approveAndSend(p2p, alice, bob, 50 * USDC_ONE, "rent");
        assertEq(usdc.balanceOf(alice), USDC_THOUSAND - 50 * USDC_ONE);
        assertEq(usdc.balanceOf(bob), 50 * USDC_ONE);
    }

    function test_SendEmitsSentEvent() public {
        vm.startPrank(alice);
        usdc.approve(address(p2p), 50 * USDC_ONE);
        vm.expectEmit(true, true, false, true, address(p2p));
        emit P2PTransfer.Sent(alice, bob, 50 * USDC_ONE, "rent");
        p2p.send(bob, 50 * USDC_ONE, "rent");
        vm.stopPrank();
    }

    function test_SendWithEmptyMemo() public {
        _approveAndSend(p2p, alice, bob, USDC_ONE, "");
        assertEq(usdc.balanceOf(bob), USDC_ONE);
    }

    function test_AssetIsUSDC() public view {
        assertEq(address(p2p.asset()), address(usdc));
    }

    function test_MaxMemoBytesIs256() public view {
        assertEq(p2p.MAX_MEMO_BYTES(), 256);
    }

    // --- Memo length boundary ----------------------------------------------------------------

    function test_SendWith255ByteMemoSucceeds() public {
        string memory m = _memo(255);
        _approveAndSend(p2p, alice, bob, USDC_ONE, m);
        assertEq(usdc.balanceOf(bob), USDC_ONE);
    }

    function test_SendWithExactly256ByteMemoSucceeds() public {
        string memory m = _memo(256);
        _approveAndSend(p2p, alice, bob, USDC_ONE, m);
        assertEq(usdc.balanceOf(bob), USDC_ONE);
    }

    function test_SendWith257ByteMemoReverts() public {
        string memory m = _memo(257);
        vm.startPrank(alice);
        usdc.approve(address(p2p), USDC_ONE);
        vm.expectRevert(abi.encodeWithSelector(P2PTransfer.MemoTooLong.selector, 257));
        p2p.send(bob, USDC_ONE, m);
        vm.stopPrank();
    }

    // --- Failure flows ------------------------------------------------------------------------

    function test_RevertOnZeroRecipient() public {
        vm.startPrank(alice);
        usdc.approve(address(p2p), USDC_ONE);
        vm.expectRevert(P2PTransfer.ZeroAddress.selector);
        p2p.send(address(0), USDC_ONE, "");
        vm.stopPrank();
    }

    function test_RevertOnSelfTransfer() public {
        vm.startPrank(alice);
        usdc.approve(address(p2p), USDC_ONE);
        vm.expectRevert(P2PTransfer.SelfTransfer.selector);
        p2p.send(alice, USDC_ONE, "");
        vm.stopPrank();
    }

    function test_RevertOnZeroAmount() public {
        vm.startPrank(alice);
        usdc.approve(address(p2p), USDC_ONE);
        vm.expectRevert(P2PTransfer.ZeroAmount.selector);
        p2p.send(bob, 0, "");
        vm.stopPrank();
    }

    function test_RevertOnInsufficientAllowance() public {
        vm.startPrank(alice);
        // no approve
        vm.expectRevert();
        p2p.send(bob, USDC_ONE, "");
        vm.stopPrank();
    }

    function test_RevertOnInsufficientBalance() public {
        address dave = makeAddr("dave");
        _giveUsdc(dave, 10 * USDC_ONE);
        vm.startPrank(dave);
        usdc.approve(address(p2p), USDC_HUNDRED);
        vm.expectRevert(); // ERC20InsufficientBalance
        p2p.send(bob, USDC_HUNDRED, "test");
        vm.stopPrank();
    }

    // --- Fuzz ---------------------------------------------------------------------------------

    function testFuzz_Send(uint96 amount, address to) public {
        vm.assume(to != address(0));
        vm.assume(to != alice);
        vm.assume(to != address(p2p));
        vm.assume(to != address(usdc));
        vm.assume(amount > 0);

        _giveUsdc(alice, amount);
        uint256 beforeRecipient = usdc.balanceOf(to);

        vm.startPrank(alice);
        usdc.approve(address(p2p), amount);
        p2p.send(to, amount, "fuzz");
        vm.stopPrank();

        assertEq(usdc.balanceOf(to) - beforeRecipient, amount);
    }

    // Fuzz memo bytes under the limit — all should succeed.
    function testFuzz_MemoLengthBelowCapSucceeds(uint16 len) public {
        len = uint16(bound(uint256(len), 0, 256));
        string memory m = _memo(len);
        _approveAndSend(p2p, alice, bob, USDC_ONE, m);
        assertEq(usdc.balanceOf(bob), USDC_ONE);
    }

    // Fuzz memo bytes above the limit — all should revert.
    function testFuzz_MemoLengthAboveCapReverts(uint16 len) public {
        len = uint16(bound(uint256(len), 257, 1024));
        string memory m = _memo(len);

        vm.startPrank(alice);
        usdc.approve(address(p2p), USDC_ONE);
        vm.expectRevert(abi.encodeWithSelector(P2PTransfer.MemoTooLong.selector, uint256(len)));
        p2p.send(bob, USDC_ONE, m);
        vm.stopPrank();
    }

    // --- Defensive guards (security improvements) ---------------------------------------------

    function test_Send_RevertWhen_RecipientIsContractItself() public {
        vm.startPrank(alice);
        usdc.approve(address(p2p), USDC_ONE);
        vm.expectRevert(P2PTransfer.InvalidRecipient.selector);
        p2p.send(address(p2p), USDC_ONE, "stuck");
        vm.stopPrank();
    }

    function test_Send_RevertWhen_RecipientIsAssetContract() public {
        vm.startPrank(alice);
        usdc.approve(address(p2p), USDC_ONE);
        vm.expectRevert(P2PTransfer.InvalidRecipient.selector);
        p2p.send(address(usdc), USDC_ONE, "stuck");
        vm.stopPrank();
    }

    function test_Constructor_RevertWhen_AssetIsZero() public {
        vm.expectRevert(P2PTransfer.ZeroAsset.selector);
        new P2PTransfer(IERC20(address(0)));
    }

    // --- Helpers ------------------------------------------------------------------------------

    function _memo(uint256 n) internal pure returns (string memory) {
        bytes memory b = new bytes(n);
        for (uint256 i = 0; i < n; i++) {
            b[i] = "a";
        }
        return string(b);
    }
}
