// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ForkBase} from "./ForkBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseForkBase is ForkBase {
    address internal constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // Known USDC holder EOA on Base mainnet (~$1.14M at research time).
    address internal constant USDC_WHALE_BASE = 0xD34EA7278e6BD48DefE656bbE263aEf11101469c;

    string internal constant RPC_ENV = "BASE_MAINNET_RPC_URL";

    function _fork() internal override returns (bool) {
        string memory rpc = vm.envOr(RPC_ENV, string(""));
        if (bytes(rpc).length == 0) return false;

        uint256 pinBlock = vm.envOr("BASE_MAINNET_FORK_BLOCK", uint256(0));
        if (pinBlock == 0) {
            vm.createSelectFork(rpc);
        } else {
            vm.createSelectFork(rpc, pinBlock);
        }

        usdc = IERC20(USDC_BASE);
        forkReady = true;
        return true;
    }

    function _giveUsdc(address user, uint256 amount) internal override {
        vm.prank(USDC_WHALE_BASE);
        usdc.transfer(user, amount);
    }
}
