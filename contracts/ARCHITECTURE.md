# Stash — Smart Contract Architecture

**Network:** Base Sepolia (chain `84532`) — testnet  
**Target mainnet:** Base (chain `8453`)  
**Underlying asset:** Circle-native USDC (6 decimals) 
**Solidity:** `0.8.26` · EVM: `cancun` · Optimizer: `10 000` runs  
**Framework:** Foundry (forge-std, OpenZeppelin Contracts 5.1.0)

---

## Table of contents

1. [System overview](#1-system-overview)
2. [Architecture diagram](#2-architecture-diagram)
3. [Contracts](#3-contracts)
   - [FlexibleVault](#31-flexiblevault)
   - [FixedVault](#32-fixedvault)
   - [P2PTransfer](#33-p2ptransfer)
4. [Transaction flows](#4-transaction-flows)
5. [Deployment — Base Sepolia](#5-deployment--base-sepolia)
6. [Security properties](#6-security-properties)
7. [Test coverage](#7-test-coverage)
8. [Known gaps & honest trade-offs](#8-known-gaps--honest-trade-offs)

---

## 1. System overview

Stash is a three-contract non-custodial USDC savings layer:

| Contract | Role | Standard |
|---|---|---|
| `FlexibleVault` | Instant-access savings pool, share-based accounting | ERC-4626 |
| `FixedVault` | Per-deposit time-locked savings (30 / 60 / 90 days) | Custom |
| `P2PTransfer` | USDC transfer wrapper with indexed memo event | Custom |

All three contracts are:
- **Immutable** — no proxy, no `delegatecall`, no `selfdestruct`
- **Admin-free** — no `Ownable`, no privileged roles, no emergency-withdraw function
- **Single-asset** — USDC address set once in constructor via `immutable`
- **Fully verified** on [BaseScan (Sepolia)](https://sepolia.basescan.org)

---

## 2. Architecture diagram

```
╔══════════════════════════════════════════════════════════════════╗
║                   CLIENT (Next.js 14 PWA)                        ║
║           wagmi v2 · viem v2 · RainbowKit                        ║
╚══════════════╦═══════════════════════════════════════════════════╝
               ║  wallet-signed txs
               ║  RPC reads (multicall, getLogs)
               ▼
╔══════════════════════════════════════════════════════════════════╗
║                     Base Sepolia  (chain 84532)                  ║
║                                                                  ║
║  ┌─────────────────────────┐  ┌──────────────────────────────┐  ║
║  │     FlexibleVault        │  │         FixedVault           │  ║
║  │  ERC-4626 share vault    │  │  per-deposit position array  │  ║
║  │  _decimalsOffset = 6     │  │  lockSeconds ∈ {30/60/90d}  │  ║
║  │  seed-burn at deploy     │  │  immutable unlockAt          │  ║
║  │  nonReentrant on all     │  │  no admin bypass             │  ║
║  │  state-changing fns      │  │  nonReentrant on deposit/    │  ║
║  │                          │  │  withdraw                    │  ║
║  └───────────┬──────────────┘  └──────────────┬───────────────┘  ║
║              │                                │                  ║
║              │  SafeERC20 transferFrom/To     │                  ║
║              │                                │                  ║
║              └──────────┬─────────────────────┘                  ║
║                         │                                        ║
║              ┌──────────▼─────────────────┐                      ║
║              │  Circle-native USDC        │                      ║
║              │  0x036CbD...dCF7e          │                      ║
║              │  (ERC-20, 6 decimals)      │                      ║
║              └────────────────────────────┘                      ║
║                                                                  ║
║  ┌─────────────────────────────────────────────────────────┐    ║
║  │  P2PTransfer  (optional — thin event wrapper)            │    ║
║  │  SafeERC20 transferFrom(sender → recipient)             │    ║
║  │  emits Sent(from, to, amount, memo) for dashboard index │    ║
║  └─────────────────────────────────────────────────────────┘    ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 3. Contracts

### 3.1 FlexibleVault

**Source:** `src/FlexibleVault.sol`  
**Address (Base Sepolia):** [`0x56fB93B19bBaF700A4a9214388d664d1A25A699E`](https://sepolia.basescan.org/address/0x56fB93B19bBaF700A4a9214388d664d1A25A699E)  
**Token symbol:** `svfUSDC` · **Token name:** `Stash Flexible USDC`  
**Inherits:** `OZ ERC4626`, `OZ ERC20`, `OZ ReentrancyGuard`

#### Storage layout

ERC-4626 manages all storage via inherited `ERC20` slots (balances, allowances, totalSupply). No custom storage variables.

#### Key design decisions

| Decision | Reason |
|---|---|
| `_decimalsOffset() = 6` | Defeats first-depositor inflation attack for a 6-decimal asset. Combined with the 1 USDC seed-burn at deploy, share price can never be manipulated to grief a real depositor. |
| Seed-burn via `Deploy.s.sol` | Deployer deposits 1 USDC and burns resulting shares to `0xdead` before any real user can interact. Permanent — `totalSupply` is always > 0. |
| `nonReentrant` on all 4 ERC-4626 entry points | Guards `deposit`, `mint`, `withdraw`, `redeem` even though OZ's ERC-4626 is already safe — defence-in-depth for any future composition. |
| No admin / no pause | Eliminates the admin-key risk vector. If a bug is found, deploy a V2 at a new address; users withdraw V1 and re-deposit. |

#### Functions

| Function | Visibility | Mutability | Description |
|---|---|---|---|
| `constructor(IERC20 asset_, string name_, string symbol_)` | — | — | Sets underlying asset, ERC-20 name/symbol via parent constructors. |
| `deposit(uint256 assets, address receiver)` | `public` | `nonReentrant` | Deposit `assets` USDC, mint shares to `receiver`. |
| `mint(uint256 shares, address receiver)` | `public` | `nonReentrant` | Mint exactly `shares`, pull the required USDC from caller. |
| `withdraw(uint256 assets, address receiver, address owner)` | `public` | `nonReentrant` | Burn shares, transfer `assets` USDC to `receiver`. |
| `redeem(uint256 shares, address receiver, address owner)` | `public` | `nonReentrant` | Burn `shares`, transfer proportional USDC to `receiver`. |
| `totalAssets()` | `public` | `view` | Returns `USDC.balanceOf(address(this))` (inherited). |
| `convertToShares(uint256 assets)` | `public` | `view` | Returns shares for a given USDC amount (inherited, uses `_decimalsOffset`). |
| `convertToAssets(uint256 shares)` | `public` | `view` | Returns USDC for a given share amount (inherited). |
| `maxWithdraw(address owner)` | `public` | `view` | Max USDC redeemable by `owner` right now (inherited). |
| `previewDeposit(uint256 assets)` | `public` | `view` | Simulates deposit — shares to be minted (inherited). |
| `previewWithdraw(uint256 assets)` | `public` | `view` | Simulates withdraw — shares to be burned (inherited). |

#### Events (inherited from ERC-4626 / ERC-20)

| Event | Emitted on |
|---|---|
| `Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)` | `deposit`, `mint` |
| `Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares)` | `withdraw`, `redeem` |
| `Transfer(address indexed from, address indexed to, uint256 value)` | Every share transfer |
| `Approval(address indexed owner, address indexed spender, uint256 value)` | `approve`, allowance changes |

---

### 3.2 FixedVault

**Source:** `src/FixedVault.sol`  
**Address (Base Sepolia):** [`0xAc49f293D7b98119E45eCC4Fd528D480dea9F4A8`](https://sepolia.basescan.org/address/0xAc49f293D7b98119E45eCC4Fd528D480dea9F4A8)  
**Inherits:** `OZ ReentrancyGuard`

#### Storage layout

```
immutable IERC20 public asset                      // USDC address

mapping(address => Position[]) private _positions  // per-user position list

struct Position {
    uint128 amount;      // USDC amount (max ~3.4 × 10^32, uint128 fits any real balance)
    uint64  unlockAt;    // unix timestamp after which withdrawal is allowed
    bool    withdrawn;   // true once the position has been closed
}
// Packed into one 32-byte storage slot: 128 + 64 + 8 = 200 bits < 256
```

#### Constants

| Constant | Value | Meaning |
|---|---|---|
| `LOCK_30_DAYS` | `2_592_000` | 30 × 24 × 3600 seconds |
| `LOCK_60_DAYS` | `5_184_000` | 60 × 24 × 3600 seconds |
| `LOCK_90_DAYS` | `7_776_000` | 90 × 24 × 3600 seconds |

#### Functions

| Function | Visibility | Mutability | Description |
|---|---|---|---|
| `constructor(IERC20 asset_)` | — | — | Sets `asset` immutable. |
| `deposit(uint256 amount, uint256 lockSeconds)` | `external` | `nonReentrant` | Opens a new position. `lockSeconds` must be 30/60/90d. Pulls USDC from caller. Returns `positionId`. |
| `withdraw(uint256 positionId)` | `external` | `nonReentrant` | Closes position `positionId`. Reverts if `withdrawn` or `block.timestamp < unlockAt`. Transfers USDC back to caller. |
| `getPosition(address owner_, uint256 positionId)` | `external` | `view` | Returns a single `Position` struct. |
| `getPositions(address owner_)` | `external` | `view` | Returns all positions (open + closed) for `owner_`. |
| `positionCount(address owner_)` | `external` | `view` | Length of `_positions[owner_]`. |
| `totalLocked()` | `external` | `view` | `asset.balanceOf(address(this))` — total USDC held. |

#### Events

| Event | Emitted on |
|---|---|
| `PositionOpened(address indexed owner, uint256 indexed positionId, uint256 amount, uint64 unlockAt)` | `deposit` |
| `PositionClosed(address indexed owner, uint256 indexed positionId, uint256 amount)` | `withdraw` |

#### Custom errors

| Error | Trigger |
|---|---|
| `ZeroAmount()` | `amount == 0` on deposit |
| `AmountTooLarge(uint256 amount)` | `amount > type(uint128).max` |
| `InvalidLockDuration(uint256 lockSeconds)` | `lockSeconds` not in {30d, 60d, 90d} |
| `PositionNotFound(uint256 positionId)` | `positionId >= positions.length` |
| `AlreadyWithdrawn(uint256 positionId)` | Position already closed |
| `NotYetUnlocked(uint64 unlockAt)` | `block.timestamp < unlockAt` |

---

### 3.3 P2PTransfer

**Source:** `src/P2PTransfer.sol`  
**Address (Base Sepolia):** [`0x0C8d08a5d2e107b6f0F09025230C8458376062e7`](https://sepolia.basescan.org/address/0x0C8d08a5d2e107b6f0F09025230C8458376062e7)  
**Inherits:** `OZ ReentrancyGuard`

#### Storage layout

```
immutable IERC20 public asset          // USDC address
uint256 public constant MAX_MEMO_BYTES = 256
```

No per-user state. The contract does not hold any USDC — every call moves funds directly from sender to recipient.

#### Functions

| Function | Visibility | Mutability | Description |
|---|---|---|---|
| `constructor(IERC20 asset_)` | — | — | Sets `asset` immutable. |
| `send(address to, uint256 amount, string calldata memo)` | `external` | `nonReentrant` | Validates inputs, pulls USDC from `msg.sender` directly to `to`, emits `Sent`. |

#### Events

| Event | Emitted on |
|---|---|
| `Sent(address indexed from, address indexed to, uint256 amount, string memo)` | `send` |

#### Custom errors

| Error | Trigger |
|---|---|
| `ZeroAddress()` | `to == address(0)` |
| `SelfTransfer()` | `to == msg.sender` |
| `ZeroAmount()` | `amount == 0` |
| `MemoTooLong(uint256 length)` | `bytes(memo).length > 256` |

---

## 4. Transaction flows

### 4.1 FlexibleVault — deposit

```
User                USDC (ERC-20)          FlexibleVault
 │                       │                      │
 │─ approve(vault, amt) ─▶                      │
 │                       │                      │
 │─────────────── deposit(assets, receiver) ───▶│
 │                       │                      │
 │                       │◀─ transferFrom ───────│  pulls USDC from user
 │                       │                      │
 │                       │                      │─ mints svfUSDC shares to receiver
 │                       │                      │
 │                       │                      │─ emits Deposit(sender, receiver, assets, shares)
```

### 4.2 FlexibleVault — withdraw

```
User                USDC (ERC-20)          FlexibleVault
 │                       │                      │
 │────────────── withdraw(assets, receiver, owner) ─▶
 │                       │                      │
 │                       │                      │─ burns shares from owner (checks allowance if owner ≠ caller)
 │                       │                      │
 │                       │◀─ transfer ───────────│  pushes USDC to receiver
 │                       │                      │
 │                       │                      │─ emits Withdraw(sender, receiver, owner, assets, shares)
```

### 4.3 FixedVault — open position

```
User                USDC (ERC-20)          FixedVault
 │                       │                      │
 │─ approve(vault, amt) ─▶                      │
 │                       │                      │
 │─────────── deposit(amount, lockSeconds) ─────▶│
 │                       │                      │
 │                       │                      │─ validates amount, lockSeconds
 │                       │                      │─ unlockAt = block.timestamp + lockSeconds
 │                       │                      │─ pushes Position{amount, unlockAt, withdrawn:false} to _positions[msg.sender]
 │                       │                      │
 │                       │◀─ safeTransferFrom ───│  pulls USDC from user
 │                       │                      │
 │                       │                      │─ emits PositionOpened(owner, positionId, amount, unlockAt)
```

### 4.4 FixedVault — close position (after unlock)

```
User                USDC (ERC-20)          FixedVault
 │                       │                      │
 │──────────── withdraw(positionId) ────────────▶│
 │                       │                      │
 │                       │                      │─ checks: positionId valid, !withdrawn, block.timestamp ≥ unlockAt
 │                       │                      │─ marks p.withdrawn = true
 │                       │                      │
 │                       │◀─ safeTransfer ───────│  pushes USDC back to msg.sender
 │                       │                      │
 │                       │                      │─ emits PositionClosed(owner, positionId, amount)
```

### 4.5 P2PTransfer — send

```
Sender              USDC (ERC-20)          P2PTransfer        Recipient
  │                      │                     │                  │
  │─ approve(p2p, amt) ─▶                      │                  │
  │                      │                     │                  │
  │──────── send(to, amount, memo) ────────────▶                  │
  │                      │                     │                  │
  │                      │                     │─ validates to, amount, memo length
  │                      │◀─ safeTransferFrom ─│                  │
  │                      │────────────────────────────────────────▶  USDC moves sender → recipient
  │                      │                     │                  │
  │                      │                     │─ emits Sent(from, to, amount, memo)
```

---

## 5. Deployment — Base Sepolia

**Network:** Base Sepolia · Chain ID `84532`  
**Deployed:** block `40,599,260` (`0x26c7edc`)  
**Deployer:** `0x16941892142A9410C84b0A6CB809aAcb38259474`  
**Deploy script:** `script/Deploy.s.sol`

### Contract addresses

| Contract | Address | Explorer |
|---|---|---|
| **USDC** (Circle-native) | `0x036CbD53842c5426634e7929541eC2318f3dCF7e` | [BaseScan](https://sepolia.basescan.org/address/0x036CbD53842c5426634e7929541eC2318f3dCF7e) |
| **FlexibleVault** | `0x56fB93B19bBaF700A4a9214388d664d1A25A699E` | [BaseScan](https://sepolia.basescan.org/address/0x56fB93B19bBaF700A4a9214388d664d1A25A699E) |
| **FixedVault** | `0xAc49f293D7b98119E45eCC4Fd528D480dea9F4A8` | [BaseScan](https://sepolia.basescan.org/address/0xAc49f293D7b98119E45eCC4Fd528D480dea9F4A8) |
| **P2PTransfer** | `0x0C8d08a5d2e107b6f0F09025230C8458376062e7` | [BaseScan](https://sepolia.basescan.org/address/0x0C8d08a5d2e107b6f0F09025230C8458376062e7) |

All three contracts are source-verified on BaseScan (Etherscan V2 API, `chainid=84532`).

### Deployment transaction hashes

| Step | Tx hash |
|---|---|
| Deploy `FlexibleVault` | [`0x49b0c0...95fb7`](https://sepolia.basescan.org/tx/0x49b0c0987d9c72e517c2d36e576054209a7eb18b1e2d0b12c514ec900c895fb7) |
| USDC `approve` (seed-burn) | [`0xbda299...70ab`](https://sepolia.basescan.org/tx/0xbda29944b52f49b1edb1f3fa28b35e46f3c8f0b9e3938a8f7cebe4336c3e70ab) |
| Seed `deposit` (1 USDC → `0xdead`) | [`0x9a00a1...7f506`](https://sepolia.basescan.org/tx/0x9a00a1697524602f1d0506d65794f5634201395cc6b0b3e380cf8d6016a7f506) |
| Deploy `FixedVault` | [`0x14fa57...2328`](https://sepolia.basescan.org/tx/0x14fa57d90693f806d7aebf85eb245d9adf14eaa4773283c6195fcf31932e2328) |
| Deploy `P2PTransfer` | [`0x437b37...1894`](https://sepolia.basescan.org/tx/0x437b372675b8b7efaecc5f77102c5dd66455b7c71460c40182bd1ee001c31894) |

### Constructor arguments

| Contract | Constructor signature | Arguments |
|---|---|---|
| `FlexibleVault` | `constructor(address asset, string name, string symbol)` | `0x036CbD...`, `"Stash Flexible USDC"`, `"svfUSDC"` |
| `FixedVault` | `constructor(address asset)` | `0x036CbD...` |
| `P2PTransfer` | `constructor(address asset)` | `0x036CbD...` |

### Seed-burn detail

At deploy time, `Deploy.s.sol` calls:
1. `USDC.approve(FlexibleVault, 1_000_000)` (1 USDC)
2. `FlexibleVault.deposit(1_000_000, 0x000...dEaD)`

This mints `1_000_000 × 10^6 = 10^12` virtual shares (due to `_decimalsOffset = 6`) and permanently burns them to `0xdead`. The result: `totalSupply` can never be zero after deploy, and any attack attempting to inflate share price would require depositing `> 10^12 USDC` — economically infeasible.

---

## 6. Security properties

### Verified by invariant testing (256 runs × 64 depth)

| Property | Test |
|---|---|
| Inflation attack fails — depositing 1 USDC never yields 0 shares | `invariant_inflationAttackFails` |
| `FlexibleVault.totalAssets()` ≥ `USDC.balanceOf(vault)` always | `invariant_balanceCoversAccounting` |
| `FlexibleVault.totalSupply > 0` at all times (seed burn is permanent) | `invariant_totalSupplyNonZero` |
| Locked FixedVault positions — `amount` and `unlockAt` never change before maturity | `invariant_lockedPositionsAreImmutable` |
| `USDC.balanceOf(FixedVault)` ≥ sum of all open (non-withdrawn) position amounts | `invariant_vaultBalanceCoversAllOpenPositions` |

### Attack surface eliminated by design

| Vector | Mitigation |
|---|---|
| Reentrancy | `ReentrancyGuard` on all state-changing entry points |
| ERC-20 return-value bugs | `SafeERC20` wraps all token calls |
| Admin key compromise | No admin — no privileged roles anywhere |
| Proxy / upgrade exploit | No proxy; contracts are immutable bytecode |
| First-depositor ERC-4626 inflation attack | `_decimalsOffset = 6` + 1 USDC seed-burn |
| Integer overflow | Solidity 0.8.26 built-in checked arithmetic |
| `uint128` overflow on FixedVault amounts | Explicit `AmountTooLarge` guard before cast |
| Double-withdraw on FixedVault | `AlreadyWithdrawn` guard checks `p.withdrawn` before transfer |
| Self-transfer via P2PTransfer | `SelfTransfer` guard: `to == msg.sender` reverts |

---

## 7. Test coverage

```
forge test
```

| Suite | Location | What it covers |
|---|---|---|
| Unit + fuzz | `test/FlexibleVault.t.sol` | All ERC-4626 paths, edge amounts (0, max), revert paths |
| Unit + fuzz | `test/FixedVault.t.sol` | Deposit/withdraw, invalid durations, early-withdraw revert, double-withdraw revert |
| Unit + fuzz | `test/P2PTransfer.t.sol` | Send paths, all 4 revert conditions, memo boundary |
| Unit | `test/MockUSDC.t.sol` | Test fixture itself |
| Fork (Base Sepolia) | `test/fork/FlexibleVault.base-sepolia.fork.t.sol` | Real Circle USDC on-chain |
| Fork (Base Sepolia) | `test/fork/FixedVault.base-sepolia.fork.t.sol` | Real Circle USDC on-chain |
| Fork (Base Sepolia) | `test/fork/P2PTransfer.base-sepolia.fork.t.sol` | Real Circle USDC on-chain |
| Invariant | `test/invariant/FlexibleVaultInvariants.t.sol` | 5 ERC-4626 safety invariants |
| Invariant | `test/invariant/FixedVaultInvariants.t.sol` | 2 time-lock safety invariants |
| Script | `test/script/Deploy.t.sol` | Full deploy + seed-burn + both revert paths |

**Coverage (unit + fuzz):**

| File | Lines | Statements | Branches | Functions |
|---|---|---|---|---|
| `src/FlexibleVault.sol` | 100% | 100% | 100% | 100% |
| `src/FixedVault.sol` | 100% | 100% | 100% | 100% |
| `src/P2PTransfer.sol` | 100% | 100% | 100% | 100% |
| `script/Deploy.s.sol` | 100% | 100% | 100% | 100% |

Run coverage locally:

```bash
forge coverage --no-match-path 'test/fork/*' --report summary
```

---

## 8. Known gaps & honest trade-offs

These are not bugs — they are deliberate MVP trade-offs. Each entry describes what's missing, why it was left out, and what to do about it before mainnet.

### 8.1 Seed-burn lives in the deploy script, not the constructor

**What:** `FlexibleVault` constructor does not seed-burn itself. If someone deploys `FlexibleVault` directly without running `Deploy.s.sol`, the inflation protection is absent until the first real deposit.

**Why left out:** Doing it inside the constructor requires the deployer to pre-approve before the contract exists — that needs a factory or `CREATE2` choreography that adds complexity beyond MVP scope.

**Fix before mainnet:** Move to a one-shot `initialize(uint256 seedAmount)` call that can only be called once (within the same deploy tx), or use a `Factory` contract that deploys + seeds atomically via `CREATE2`.

---

### 8.2 No ERC-2612 permit support

**What:** Both `FlexibleVault.deposit` and `FixedVault.deposit` require the user to submit an `approve` transaction before depositing — two transactions for every first interaction with a new vault.

**Why left out:** Adding `permit` requires the underlying token (`USDC`) to implement ERC-2612. Circle's canonical USDC on Base does implement permit (`EIP-3009`), but wiring `depositWithPermit` adds ~30 LoC per vault and frontend signature handling.

**Fix before mainnet:** Add `depositWithPermit(uint256 assets, address receiver, uint256 deadline, uint8 v, bytes32 r, bytes32 s)` to `FlexibleVault` using `IERC20Permit`. Same pattern for `FixedVault.depositWithPermit`.

---

### 8.3 `FixedVault.totalLocked()` uses `balanceOf`, not sum-of-open-positions

**What:** `totalLocked()` returns `asset.balanceOf(address(this))`. If USDC is accidentally sent directly to the contract (not via `deposit`), this overstates the total locked. There is also no view function that returns only the sum of open (non-withdrawn) positions.

**Why left out:** Keeping a running `_totalOpen` counter adds one SSTORE per deposit/withdraw. For MVP it is acceptable that `totalLocked` ≈ balance.

**Fix before mainnet:** Add `uint256 private _totalOpen` updated in `deposit` (+amount) and `withdraw` (-amount). Expose as `totalOpenLocked()`. Rename current `totalLocked()` to `vaultBalance()` so the distinction is clear.

---

### 8.4 No `getActivePositions` view helper

**What:** `getPositions(address)` returns all positions — open and closed. The frontend must filter `withdrawn == false` in JavaScript. For users with many historical positions this is more data than needed.

**Why left out:** On-chain filtering loops are gas-expensive for writes. For a read-only view at MVP scale (< 100 positions per user) off-chain filtering is fine.

**Fix before mainnet:** Add `getOpenPositions(address owner_)` that iterates and returns only `withdrawn == false` positions. Gas cost is only at read time; no write overhead.

---

### 8.5 P2PTransfer is easily bypassed

**What:** Users can send USDC directly via the USDC contract without going through `P2PTransfer`. The only benefit of routing through `P2PTransfer` is the `Sent(from, to, amount, memo)` event, which makes transaction history indexing easier and adds an on-chain memo.

**Why kept in:** The memo and consistent event structure simplify the dashboard (`getLogs` on one address, one event type). Removing it means the dashboard must parse raw USDC `Transfer` events and has no memo field.

**Trade-off:**  `P2PTransfer` is optional. The frontend can fall back to `USDC.Transfer` events filtered by user address. The only regression is losing the memo.