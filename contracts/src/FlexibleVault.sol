// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// A flexible-savings vault. Users can deposit and withdraw freely; shares are redeemable for the same amount of underlying at any time.
contract FlexibleVault is ERC4626, ReentrancyGuard {
    error ZeroAsset();

    constructor(IERC20 asset_, string memory name_, string memory symbol_) ERC20(name_, symbol_) ERC4626(asset_) {
        if (address(asset_) == address(0)) revert ZeroAsset();
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 6;
    }

    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override nonReentrant returns (uint256) {
        return super.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }
}
