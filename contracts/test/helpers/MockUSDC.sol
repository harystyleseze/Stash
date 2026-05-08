// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor(uint256 initialMint) ERC20("Mock USD Coin", "USDC") {
        if (initialMint > 0) {
            _mint(msg.sender, initialMint);
        }
    }

    // Testnet faucet: anyone can mint themselves test USDC. Do not use in production.
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    // Testnet faucet: anyone can mint themselves test USDC. Do not use in production.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
