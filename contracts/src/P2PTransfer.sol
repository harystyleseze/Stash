// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// A simple P2P transfer contract. Users can send the underlying stablecoin to any address with an optional memo.
contract P2PTransfer is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;

    uint256 public constant MAX_MEMO_BYTES = 256;

    error ZeroAddress();
    error SelfTransfer();
    error ZeroAmount();
    error MemoTooLong(uint256 length);
    error InvalidRecipient();
    error ZeroAsset();

    event Sent(address indexed from, address indexed to, uint256 amount, string memo);

    constructor(IERC20 asset_) {
        if (address(asset_) == address(0)) revert ZeroAsset();
        asset = asset_;
    }

    function send(address to, uint256 amount, string calldata memo) external nonReentrant {
        if (to == address(0)) revert ZeroAddress();
        if (to == msg.sender) revert SelfTransfer();
        if (to == address(this) || to == address(asset)) revert InvalidRecipient();
        if (amount == 0) revert ZeroAmount();
        if (bytes(memo).length > MAX_MEMO_BYTES) revert MemoTooLong(bytes(memo).length);

        asset.safeTransferFrom(msg.sender, to, amount);

        emit Sent(msg.sender, to, amount, memo);
    }
}
