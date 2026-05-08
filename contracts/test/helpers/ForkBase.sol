// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {TestBase} from "./TestBase.sol";

abstract contract ForkBase is TestBase {
    bool internal forkReady;

    // Skips the test body if the fork wasn't enabled.
    modifier onlyWhenForked() {
        if (!forkReady) {
            vm.skip(true);
            return;
        }
        _;
    }

    function _fork() internal virtual returns (bool);
}
