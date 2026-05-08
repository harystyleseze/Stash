// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseSepoliaForkBase} from "../helpers/BaseSepoliaForkBase.sol";
import {P2PTransfer} from "../../src/P2PTransfer.sol";

contract P2PTransferBaseSepoliaForkTest is BaseSepoliaForkBase {
    P2PTransfer internal p2p;

    function setUp() public {
        if (!_fork()) return;
        _initActors();
        p2p = _deployP2P();
        _giveUsdc(alice, 500 * USDC_ONE);
    }

    function test_BaseSepolia_Send() public onlyWhenForked {
        _approveAndSend(p2p, alice, bob, 50 * USDC_ONE, "rent");
        assertEq(usdc.balanceOf(bob), 50 * USDC_ONE);
    }

    function test_BaseSepolia_SendEmitsSentEvent() public onlyWhenForked {
        vm.startPrank(alice);
        usdc.approve(address(p2p), 25 * USDC_ONE);
        vm.expectEmit(true, true, false, true, address(p2p));
        emit P2PTransfer.Sent(alice, bob, 25 * USDC_ONE, "invoice-42");
        p2p.send(bob, 25 * USDC_ONE, "invoice-42");
        vm.stopPrank();
    }

    function test_BaseSepolia_SelfSendReverts() public onlyWhenForked {
        vm.startPrank(alice);
        usdc.approve(address(p2p), USDC_ONE);
        vm.expectRevert(P2PTransfer.SelfTransfer.selector);
        p2p.send(alice, USDC_ONE, "");
        vm.stopPrank();
    }
}
