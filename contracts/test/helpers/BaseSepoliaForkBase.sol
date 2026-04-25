// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ForkBase} from "./ForkBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Fork-test base for **Base Sepolia** (chain id 84532). Exercises the Stash contracts
///         against the real **Circle-native USDC** on Base Sepolia:
///
///             `0x036CbD53842c5426634e7929541eC2318f3dCF7e`
///
///         This is our deployment chain, so this is the primary fork target. Fund actors by
///         impersonating a known USDC holder EOA via `vm.prank + transfer`.
///
///         Opt in via `BASE_SEPOLIA_RPC_URL`. Without it the suite skips cleanly.
abstract contract BaseSepoliaForkBase is ForkBase {
    /// @notice Canonical Circle-native USDC on Base Sepolia (symbol `USDC`, 6 decimals).
    ///         Source: Circle's official USDC registry
    ///         (https://developers.circle.com/stablecoins/usdc-contract-addresses).
    address internal constant USDC_BASE_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    /// @notice Verified USDC holder EOA at research time (~29.7B USDC held on Base Sepolia).
    ///         Testnet balances drift — if this address runs dry, pick another from BaseScan:
    ///         https://sepolia.basescan.org/token/0x036CbD53842c5426634e7929541eC2318f3dCF7e#balances
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

    /// @dev Fund `user` by impersonating a USDC holder and transferring. Uses the real token's
    ///      transfer path (no `deal()` storage tricks) so every test exercises the same code a
    ///      production user would.
    function _giveUsdc(address user, uint256 amount) internal override {
        vm.prank(USDC_WHALE_BASE_SEPOLIA);
        usdc.transfer(user, amount);
    }
}
