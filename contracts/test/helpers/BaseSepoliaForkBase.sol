// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ForkBase} from "./ForkBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseSepoliaForkBase is ForkBase {
    address internal constant USDC_BASE_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    address internal constant USDC_WHALE_BASE_SEPOLIA = 0xFaEc9cDC3Ef75713b48f46057B98BA04885e3391;

    string internal constant RPC_ENV = "BASE_SEPOLIA_RPC_URL";

    /// @inheritdoc ForkBase
    function _fork() internal override returns (bool) {
        string memory rpc = vm.envOr(RPC_ENV, string(""));
        if (bytes(rpc).length == 0) return false;

        uint256 pinBlock = vm.envOr("BASE_SEPOLIA_FORK_BLOCK", uint256(0));
        if (pinBlock == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, pinBlock);
        }

        usdc = IERC20(USDC_BASE_SEPOLIA);
        forkReady = true;
        return true;
    }

    function _giveUsdc(address user, uint256 amount) internal override {
        vm.prank(USDC_WHALE_BASE_SEPOLIA);
        usdc.transfer(user, amount);
    }
}
