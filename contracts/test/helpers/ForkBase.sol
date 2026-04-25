// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {TestBase} from "./TestBase.sol";

/// @dev Common scaffolding for fork-tests: a boolean gate (`forkReady`) plus a modifier that
///      transparently skips the test when the fork couldn't be set up (e.g. no RPC env var).
///      Concrete chain-specific bases (LiskForkBase, BaseForkBase, EthMainnetForkBase) extend
///      this and provide the real USDC + whale address + RPC env-var name.
abstract contract ForkBase is TestBase {
    bool internal forkReady;

    /// @dev Skips the test body if the fork wasn't enabled.
    modifier onlyWhenForked() {
        if (!forkReady) {
            vm.skip(true);
            return;
        }
        _;
    }

    /// @dev Must be implemented by the concrete base. Returns true iff a fork was successfully
    ///      created and `usdc` was pointed at the chain's canonical stablecoin. Implementations
    ///      should return false cleanly when the required RPC env var is unset, so CI without
    ///      network access still goes green.
    function _fork() internal virtual returns (bool);
}
