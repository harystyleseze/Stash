// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// A fixed-savings vault. Users can open multiple positions, each with a chosen lock duration and amount.
contract FixedVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Position {
        uint128 amount;
        uint64 unlockAt;
        bool withdrawn;
    }

    IERC20 public immutable asset;

    mapping(address => Position[]) private _positions;

    uint256 public constant LOCK_30_DAYS = 30 days;
    uint256 public constant LOCK_60_DAYS = 60 days;
    uint256 public constant LOCK_90_DAYS = 90 days;
    uint256 public constant MIN_DEPOSIT = 1e6;

    error ZeroAmount();
    error InvalidLockDuration(uint256 lockSeconds);
    error AmountTooLarge(uint256 amount);
    error PositionNotFound(uint256 positionId);
    error AlreadyWithdrawn(uint256 positionId);
    error NotYetUnlocked(uint64 unlockAt);
    error AmountBelowMinimum(uint256 amount, uint256 minimum);
    error ZeroAsset();

    event PositionOpened(address indexed owner, uint256 indexed positionId, uint256 amount, uint64 unlockAt);
    event PositionClosed(address indexed owner, uint256 indexed positionId, uint256 amount);


    constructor(IERC20 asset_) {
        if (address(asset_) == address(0)) revert ZeroAsset();
        asset = asset_;
    }


    function deposit(uint256 amount, uint256 lockSeconds) external nonReentrant returns (uint256 positionId) {
        if (amount == 0) revert ZeroAmount();
        if (amount < MIN_DEPOSIT) revert AmountBelowMinimum(amount, MIN_DEPOSIT);
        if (amount > type(uint128).max) revert AmountTooLarge(amount);
        if (lockSeconds != LOCK_30_DAYS && lockSeconds != LOCK_60_DAYS && lockSeconds != LOCK_90_DAYS) {
            revert InvalidLockDuration(lockSeconds);
        }

        
        uint64 unlockAt = uint64(block.timestamp + lockSeconds);

        positionId = _positions[msg.sender].length;
        
        _positions[msg.sender].push(Position({amount: uint128(amount), unlockAt: unlockAt, withdrawn: false}));

        asset.safeTransferFrom(msg.sender, address(this), amount);

        emit PositionOpened(msg.sender, positionId, amount, unlockAt);
    }

    function withdraw(uint256 positionId) external nonReentrant {
        Position[] storage ownerPositions = _positions[msg.sender];
        if (positionId >= ownerPositions.length) revert PositionNotFound(positionId);

        Position storage p = ownerPositions[positionId];
        if (p.withdrawn) revert AlreadyWithdrawn(positionId);
        if (block.timestamp < p.unlockAt) revert NotYetUnlocked(p.unlockAt);

        uint256 amount = p.amount;
        p.withdrawn = true;

        asset.safeTransfer(msg.sender, amount);

        emit PositionClosed(msg.sender, positionId, amount);
    }


    function getPositions(address owner_) external view returns (Position[] memory) {
        return _positions[owner_];
    }

    function getOpenPositions(address owner_) external view returns (Position[] memory) {
        Position[] storage all = _positions[owner_];
        uint256 totalLen = all.length;
        uint256 openCount;
        for (uint256 i = 0; i < totalLen; i++) {
            if (!all[i].withdrawn) {
                openCount++;
            }
        }
        Position[] memory open = new Position[](openCount);
        uint256 j;
        for (uint256 i = 0; i < totalLen; i++) {
            if (!all[i].withdrawn) {
                open[j] = all[i];
                j++;
            }
        }
        return open;
    }

    function getPosition(address owner_, uint256 positionId) external view returns (Position memory) {
        if (positionId >= _positions[owner_].length) revert PositionNotFound(positionId);
        return _positions[owner_][positionId];
    }

    function positionCount(address owner_) external view returns (uint256) {
        return _positions[owner_].length;
    }

    function totalLocked() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }
}
