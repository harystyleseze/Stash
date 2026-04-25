# Stash Contracts — Base deployment

**Stash** is a smart-contract neobank for holding USDC savings on-chain. Three primitives:

- **`FlexibleVault`** — ERC-4626 vault for instant-access savings. Inflation-attack-proof via `_decimalsOffset() = 6` + seed-burn at deploy.
- **`FixedVault`** — time-locked savings (30 / 60 / 90 days), per-deposit immutable `unlockAt`, no admin bypass.
- **`P2PTransfer`** — thin USDC transfer wrapper emitting an indexable `Sent(from, to, amount, memo)` event.

**Deployment target:** Base Sepolia (chain `84532`) for development; Base mainnet (chain `8453`) for production.
**Underlying asset:** real Circle-native USDC — no mock tokens, no bridged wrappers.

| Network | Chain ID | Canonical USDC |
|---|---|---|
| **Base Sepolia** (testnet) | 84532 | [`0x036CbD53842c5426634e7929541eC2318f3dCF7e`](https://sepolia.basescan.org/address/0x036CbD53842c5426634e7929541eC2318f3dCF7e) |
| **Base Mainnet** | 8453 | [`0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`](https://basescan.org/address/0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913) |

---

## Table of contents

1. [Repository layout](#1-repository-layout)
2. [Prerequisites](#2-prerequisites)
3. [Clone + install](#3-clone--install)
4. [Build](#4-build)
5. [Run tests](#5-run-tests)
6. [Fork tests against real USDC](#6-fork-tests-against-real-usdc)
7. [Coverage](#7-coverage)
8. [Deploy to Base Sepolia — step by step](#8-deploy-to-base-sepolia--step-by-step)
9. [Verify on BaseScan — step by step](#9-verify-on-basescan--step-by-step)
10. [Deploy to Base mainnet](#10-deploy-to-base-mainnet)
11. [Scripts reference](#11-scripts-reference)
12. [Contract reference](#12-contract-reference)
13. [Test architecture](#13-test-architecture)
14. [Security properties verified](#14-security-properties-verified)
15. [Troubleshooting](#15-troubleshooting)
16. [License](#16-license)

---

## 1. Repository layout

Everything contract-related lives under `contracts/`. No parallel folders — helper shell scripts, env templates, and the Foundry workspace are all in one place.

```
contracts/
├── foundry.toml                        # Foundry profile (named RPCs + Etherscan V2 configured)
├── foundry.lock                        # forge-std version pin
├── remappings.txt
├── .env                                # local only (gitignored; created from .env.example)
├── .env.example                        # copy to .env, fill values
├── README.md                           # you are here
├── scripts/
│   ├── install-oz.sh                   # fetch OpenZeppelin 5.1.0 via tagged tarball
│   └── verify.sh                       # BaseScan (or Blockscout) verification wrapper
├── src/
│   ├── FlexibleVault.sol               # ERC-4626 + _decimalsOffset=6 + nonReentrant
│   ├── FixedVault.sol                  # per-deposit immutable time-lock
│   └── P2PTransfer.sol                 # USDC transfer + memo event
├── script/
│   └── Deploy.s.sol                    # deploys all three + seed-burns FlexibleVault
├── test/
│   ├── helpers/
│   │   ├── TestBase.sol                # actors, constants, reusable action helpers
│   │   ├── MockUSDC.sol                # test-only 6-dp ERC-20 (never deployed on-chain)
│   │   ├── ForkBase.sol                # abstract fork gate + onlyWhenForked modifier
│   │   ├── BaseSepoliaForkBase.sol     # primary fork target (Base Sepolia + real Circle USDC)
│   │   └── BaseForkBase.sol            # secondary fork target (Base mainnet + Circle USDC)
│   ├── fork/                           # *.base-sepolia.fork.t.sol — real USDC on Base Sepolia
│   ├── invariant/                      # 2 handler contracts + 2 invariant suites
│   ├── script/Deploy.t.sol             # exercises Deploy.s.sol end-to-end
│   ├── FlexibleVault.t.sol             # unit + fuzz against MockUSDC
│   ├── FixedVault.t.sol
│   ├── P2PTransfer.t.sol
│   └── MockUSDC.t.sol
└── lib/
    ├── forge-std/                      # git submodule
    └── openzeppelin-contracts/         # installed by scripts/install-oz.sh (tarball)
```

---

## 2. Prerequisites

| Tool | Minimum | Install |
|---|---|---|
| **Foundry** (`forge`, `cast`) | 1.5 | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| **git** | 2.30+ | OS package |
| **jq** | 1.6+ | `brew install jq` · `apt install jq` |
| **curl** | any | usually preinstalled |

Verify: `forge --version && git --version && jq --version`.

---

## 3. Clone + install

```bash
git clone --recurse-submodules https://github.com/harystyleseze/stash.git
cd stash/contracts
./scripts/install-oz.sh
```

- `--recurse-submodules` pulls `lib/forge-std`. If you forgot: `git submodule update --init --recursive`.
- `install-oz.sh` downloads OpenZeppelin Contracts 5.1.0 as a tagged tarball (more resilient than `forge install` on flaky networks). Idempotent — rerunning is a no-op.

---

## 4. Build

```bash
forge build
```

Expected: `Compiler run successful!`. Solidity `0.8.26`, EVM version `cancun`.

---

## 5. Run tests

```bash
forge test
```

Expected output tail:

```
Ran 10 test suites … 85 tests passed, 0 failed, 8 skipped (93 total tests)
```

- **85 passing** = unit + fuzz + invariant + script + MockUSDC helper tests.
- **8 skipped** = fork tests (they skip cleanly when `BASE_SEPOLIA_RPC_URL` / `BASE_MAINNET_RPC_URL` are unset — see §6).

Narrower commands:

```bash
forge test -vv                              # verbose per-test output
forge test --match-contract FlexibleVault   # one test contract
forge test --no-match-path 'test/fork/*'    # skip every fork file
```

---

## 6. Fork tests against real USDC

Primary: **Base Sepolia against Circle's real USDC** (`0x036CbD53842c5426634e7929541eC2318f3dCF7e`). Actors are funded by impersonating a known USDC holder.

```bash
export BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
forge test --match-path 'test/fork/*.base-sepolia.fork.t.sol' -vv
```

Secondary (Base mainnet — canonical USDC cross-check):

```bash
export BASE_MAINNET_RPC_URL=https://mainnet.base.org
# no base mainnet fork tests ship by default — use the BaseForkBase helper to add your own.
```

### Pin a fork block for reproducibility

```bash
export BASE_SEPOLIA_FORK_BLOCK=15000000    # or any recent block
```

Without a pin, forks use the RPC's latest block — non-deterministic but reflects today's real state.

---

## 7. Coverage

```bash
forge coverage --no-match-path 'test/fork/*' --report summary
```

Expected (lines / statements / branches / funcs):

| File | Coverage |
|---|---|
| `src/FlexibleVault.sol` | 100 / 100 / 100 / 100 |
| `src/FixedVault.sol` | 100 / 100 / 100 / 100 |
| `src/P2PTransfer.sol` | 100 / 100 / 100 / 100 |
| `script/Deploy.s.sol` | 100 / 100 / 100 / 100 |
| `test/helpers/MockUSDC.sol` | 100 / 100 / 100 / 100 |

Every production + script line, statement, branch, and function is exercised.

HTML report:
```bash
forge coverage --no-match-path 'test/fork/*' --report lcov
# brew install lcov   (or: apt install lcov)
genhtml -o coverage-html lcov.info
open coverage-html/index.html
```

---

## 8. Deploy to Base Sepolia — step by step

Everything below assumes you are in the `contracts/` directory.

### 8.1 Create or pick a deploy wallet

Generate a dedicated key — **never reuse a key that holds real mainnet funds**:

```bash
cast wallet new
# Address:     0x46D0...
# Private key: 0x....
```

Save both to a password manager. The address is public; the private key is not.

### 8.2 Fund the wallet with Base Sepolia ETH

Any of these faucets work. You only need ~0.01 ETH for the full deploy + verify flow:

| Faucet | URL |
|---|---|
| Coinbase CDP | https://portal.cdp.coinbase.com/products/faucet |
| Alchemy | https://www.alchemy.com/faucets/base-sepolia |
| thirdweb | https://thirdweb.com/base-sepolia-testnet |
| QuickNode | https://faucet.quicknode.com/drip |

Confirm balance:
```bash
cast balance 0xYourDeployer --rpc-url https://sepolia.base.org --ether
```

### 8.3 Mint 1 USDC to the wallet (required for seed-burn)

`Deploy.s.sol` seeds FlexibleVault with 1 USDC and burns the resulting shares to `0xdead`. This pre-empts the ERC-4626 first-depositor inflation attack. The deployer must therefore hold ≥ 1 USDC in Circle's Base Sepolia USDC before running the script.

Visit **Circle's testnet USDC faucet**: https://faucet.circle.com

1. Select **Base Sepolia**.
2. Paste your deployer address.
3. Request 20 USDC (limit 20 per 2 hours per address).

Confirm:
```bash
cast call 0x036CbD53842c5426634e7929541eC2318f3dCF7e \
  "balanceOf(address)(uint256)" \
  0xYourDeployer \
  --rpc-url https://sepolia.base.org
# Expect a value ≥ 1_000_000  (= 1 USDC, 6 decimals)
```

### 8.4 Configure `.env`

```bash
cp .env.example .env
```

Edit `.env` — the only fields you must change:

```bash
PRIVATE_KEY=0x<your-deploy-key>
# BASE_SEPOLIA_RPC_URL defaults to https://sepolia.base.org — keep as-is unless you have a dedicated RPC.
# USDC_ADDRESS already points at Circle's real Base Sepolia USDC — leave it.
ETHERSCAN_API_KEY=<your-v2-key>    # optional now; required for §9 BaseScan verification
```

Register for the Etherscan V2 API key (free, one key works across all supported chains): https://etherscan.io/myapikey

Load `.env` into the current shell:

```bash
set -a; source .env; set +a
```

> `forge script` reads env variables when it runs; every new terminal needs to reload `.env`.

### 8.5 Deploy

```bash
forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

Expected output tail:

```
============ Stash deployed ============
Chain id:          84532
USDC (underlying): 0x036CbD53842c5426634e7929541eC2318f3dCF7e
FlexibleVault:     0x<FLEX>
FixedVault:        0x<FIXED>
P2PTransfer:       0x<P2P>
Seed burn (USDC):  1000000
Seed recipient:    0x000000000000000000000000000000000000dEaD
========================================
```

Copy the three addresses — you need them for verification in §9. The broadcast details (transaction hashes, gas used) are also recorded under `broadcast/Deploy.s.sol/84532/run-latest.json`.

### 8.6 (Optional) Give your test wallet some USDC

If you want to interact with the deployed vaults from another wallet (e.g. for smoke testing), mint USDC to it from the Circle faucet the same way as §8.3 — there's no MockUSDC faucet to call because we use real USDC everywhere on Base.

---

## 9. Verify on BaseScan — step by step

Verification makes the contracts' source visible on https://sepolia.basescan.org so anyone can audit them by clicking the "Contract" tab. Two paths:

### Path A (recommended): `scripts/verify.sh` wrapper

```bash
CHAIN=base-sepolia \
USDC_ADDRESS=0x036CbD53842c5426634e7929541eC2318f3dCF7e \
FLEXIBLE_VAULT=0x<FLEX> \
FIXED_VAULT=0x<FIXED> \
P2P_TRANSFER=0x<P2P> \
ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY \
./scripts/verify.sh
```

The script ABI-encodes constructor args with `cast abi-encode`, submits all three verifications to BaseScan (via the Etherscan V2 unified API), and prints the explorer URLs at the end.

### Path B (manual): raw `forge verify-contract`

Useful for re-verifying a single contract or debugging.

```bash
# -- FlexibleVault --
FLEX_CTOR=$(cast abi-encode "constructor(address,string,string)" \
  "$USDC_ADDRESS" "Stash Flexible USDC" "svfUSDC")
forge verify-contract \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --chain 84532 \
  --verifier etherscan \
  --verifier-url 'https://api.etherscan.io/v2/api?chainid=84532' \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args "$FLEX_CTOR" \
  --watch \
  $FLEXIBLE_VAULT \
  src/FlexibleVault.sol:FlexibleVault

# -- FixedVault --
FIXED_CTOR=$(cast abi-encode "constructor(address)" "$USDC_ADDRESS")
forge verify-contract \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --chain 84532 \
  --verifier etherscan \
  --verifier-url 'https://api.etherscan.io/v2/api?chainid=84532' \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args "$FIXED_CTOR" \
  --watch \
  $FIXED_VAULT \
  src/FixedVault.sol:FixedVault

# -- P2PTransfer --
P2P_CTOR=$(cast abi-encode "constructor(address)" "$USDC_ADDRESS")
forge verify-contract \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --chain 84532 \
  --verifier etherscan \
  --verifier-url 'https://api.etherscan.io/v2/api?chainid=84532' \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args "$P2P_CTOR" \
  --watch \
  $P2P_TRANSFER \
  src/P2PTransfer.sol:P2PTransfer
```

### Path C (no-API-key alternative): Blockscout

If you'd rather not register an Etherscan V2 key, the Base Sepolia Blockscout instance accepts verification without a key:

```bash
VERIFIER=blockscout \
CHAIN=base-sepolia \
USDC_ADDRESS=0x036CbD53842c5426634e7929541eC2318f3dCF7e \
FLEXIBLE_VAULT=0x<FLEX> \
FIXED_VAULT=0x<FIXED> \
P2P_TRANSFER=0x<P2P> \
./scripts/verify.sh
```

Source will appear at `https://base-sepolia.blockscout.com/address/<ADDR>`.

### 9.1 Confirm on BaseScan

Open each contract and look for a green **"Contract Source Code Verified"** badge plus a `Read Contract` / `Write Contract` tab:

- `https://sepolia.basescan.org/address/<FLEX>`
- `https://sepolia.basescan.org/address/<FIXED>`
- `https://sepolia.basescan.org/address/<P2P>`

---

## 10. Deploy to Base mainnet

Same commands, different chain. Circle-native USDC at `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`.

```bash
# edit .env
PRIVATE_KEY=0x<production-deploy-key>
BASE_MAINNET_RPC_URL=https://mainnet.base.org
USDC_ADDRESS=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
ETHERSCAN_API_KEY=<your-v2-key>
```

Bridge ≥ 1 USDC and ~0.01 ETH to the deployer, then:

```bash
set -a; source .env; set +a

forge script script/Deploy.s.sol \
  --rpc-url $BASE_MAINNET_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast

# Verify
CHAIN=base-mainnet \
USDC_ADDRESS=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 \
FLEXIBLE_VAULT=0x<FLEX> FIXED_VAULT=0x<FIXED> P2P_TRANSFER=0x<P2P> \
./scripts/verify.sh
```

> ⚠ **Stash is not audited.** Do not deploy to mainnet with real user funds until an independent audit is complete.

---

## 11. Scripts reference

### `scripts/install-oz.sh`
Downloads OpenZeppelin Contracts v5.1.0 as a tagged release tarball into `contracts/lib/openzeppelin-contracts/`. Idempotent — skips if the directory already exists. No git submodule, so no clone-disconnect issues on CI.

### `scripts/verify.sh`
Wraps `forge verify-contract` for the three Stash contracts. Inputs via environment variables:

| Variable | Required | Description |
|---|---|---|
| `CHAIN` | no (default `base-sepolia`) | `base-sepolia` or `base-mainnet` |
| `VERIFIER` | no (default `etherscan`) | `etherscan` (BaseScan via V2) or `blockscout` |
| `USDC_ADDRESS` | yes | Underlying the vaults were deployed against |
| `FLEXIBLE_VAULT` | yes | Address from §8.5 output |
| `FIXED_VAULT` | yes | Address from §8.5 output |
| `P2P_TRANSFER` | yes | Address from §8.5 output |
| `ETHERSCAN_API_KEY` | yes for `VERIFIER=etherscan` | Etherscan V2 key (https://etherscan.io/myapikey) |
| `RPC_URL` | no | Overrides the chain's default RPC |

### `script/Deploy.s.sol` (Foundry Solidity script)
Reads `PRIVATE_KEY` and `USDC_ADDRESS` from env. Deploys all three Stash contracts, then seeds FlexibleVault with 1 USDC and burns the shares to `0xdead`. Prints every address.

**Env vars it reads:**
- `PRIVATE_KEY` — the deploy EOA's key.
- `USDC_ADDRESS` — the underlying stablecoin. On Base Sepolia: `0x036CbD5...eB48`. On Base mainnet: `0x833589f...02913`.

**Preconditions:**
- Deployer holds ≥ 1 USDC of the chosen underlying (for the seed-burn).
- `USDC_ADDRESS` is non-zero (script reverts with `"USDC_ADDRESS must not be zero"` otherwise).

---

## 12. Contract reference

### `FlexibleVault` (src/FlexibleVault.sol)
- Inherits `ERC4626` (OZ 5.1.0) + `ReentrancyGuard`.
- `_decimalsOffset() = 6` — defeats the first-depositor inflation attack for a 6-decimal asset.
- `nonReentrant` on `deposit`, `mint`, `withdraw`, `redeem`.
- No admin, no proxy, no migration function, no `selfdestruct`.

### `FixedVault` (src/FixedVault.sol)
- Per-user `Position[]`, each `{amount uint128, unlockAt uint64, withdrawn bool}` packed into a single storage slot.
- `deposit(amount, lockSeconds)` — `lockSeconds ∈ {30 days, 60 days, 90 days}`.
- `withdraw(positionId)` reverts `NotYetUnlocked(unlockAt)` before maturity, `AlreadyWithdrawn` after.
- No admin, no bypass, no `selfdestruct`, no `delegatecall`.

### `P2PTransfer` (src/P2PTransfer.sol)
- `send(to, amount, memo)` — `SafeERC20.safeTransferFrom(msg.sender → to)`, emits `Sent(from, to, amount, memo)`.
- Validates: non-zero address, non-self, non-zero amount, memo ≤ 256 bytes.

### `MockUSDC` (test/helpers/MockUSDC.sol) — **test only**
- 6-decimal ERC-20 used as a test fixture. **Never deployed to a live chain.**
- Located under `test/helpers/` so it can't accidentally be targeted by `forge script`.

---

## 13. Test architecture

- **`test/helpers/TestBase.sol`** — shared actors (`alice` / `bob` / `carol` / `attacker` / `DEAD`), USDC amount constants, reusable action helpers (`_approveAndFlexDeposit`, `_approveAndFixedDeposit`, `_approveAndSend`, `_skip`). Overridable `_giveUsdc` hook.
- **`test/helpers/ForkBase.sol`** — abstract: `forkReady` flag + `onlyWhenForked` modifier + virtual `_fork()`.
- **`test/helpers/BaseSepoliaForkBase.sol`** — primary fork helper. Real Circle USDC on Base Sepolia. Funds actors by impersonating a known USDC holder EOA.
- **`test/helpers/BaseForkBase.sol`** — secondary fork helper. Real Circle USDC on Base mainnet.
- **`test/FlexibleVault.t.sol` / `FixedVault.t.sol` / `P2PTransfer.t.sol`** — unit + fuzz tests against MockUSDC.
- **`test/MockUSDC.t.sol`** — constructor branches + `mint` faucet.
- **`test/script/Deploy.t.sol`** — full deploy-script run + both failure flows (zero USDC address, deployer without 1 USDC).
- **`test/fork/*.base-sepolia.fork.t.sol`** — Lisk-ahem… **Base** Sepolia fork tests against real Circle USDC.
- **`test/invariant/`** — property-based invariant campaigns for both vaults.

---

## 14. Security properties verified

| Invariant | Test | Campaign |
|---|---|---|
| First-depositor inflation attack cannot grief a 1-USDC deposit to 0 shares | `invariant_inflationAttackFails` | 256 runs × 128 calls |
| FlexibleVault's USDC balance ≥ totalAssets | `invariant_balanceCoversAccounting` | 256 runs |
| FlexibleVault.totalSupply > 0 (seed burn permanent) | `invariant_totalSupplyNonZero` | 256 runs |
| Locked FixedVault positions' (amount, unlockAt) never change before maturity | `invariant_lockedPositionsAreImmutable` | 256 runs × 64 depth |
| FixedVault's USDC balance ≥ sum of unwithdrawn open positions | `invariant_vaultBalanceCoversAllOpenPositions` | 256 runs × 64 depth |

Plus 40+ unit + fuzz tests covering every documented revert path (zero address, self-transfer, zero amount, oversized memo, invalid lock duration, over-withdraw, double-withdraw, missing approval, insufficient balance, etc.).

---

## 15. Troubleshooting

**`forge install` disconnects mid-clone.**
Use `./scripts/install-oz.sh` — it pulls the tagged tarball, which survives flaky networks.

**`forge fmt --check` fails in CI.**
Run `forge fmt` locally before committing; format profile is in `foundry.toml`.

**`forge coverage` is slow.**
Exclude fork tests: `forge coverage --no-match-path 'test/fork/*'`.

**`forge script` reverts with `USDC_ADDRESS must not be zero`.**
You didn't load `.env` into the current shell — `forge script` reads env at invocation time. Run `set -a; source .env; set +a` first.

**`forge script` reverts with `Deployer must hold at least 1 USDC for seed-burn`.**
Mint USDC from Circle's faucet (§8.3) before running.

**`forge verify-contract` fails with "Missing/Invalid API Key".**
`ETHERSCAN_API_KEY` isn't set or is wrong. One V2 key works for all chains — grab it at https://etherscan.io/myapikey. Or switch to Blockscout: `VERIFIER=blockscout ./scripts/verify.sh` (no key needed).

**Fork test says "insufficient balance" against real USDC.**
The whale address's balance has drifted since research time. Pin a known-good block: `export BASE_SEPOLIA_FORK_BLOCK=<number>`. Or pick a new whale from https://sepolia.basescan.org/token/0x036CbD53842c5426634e7929541eC2318f3dCF7e#balances and update `test/helpers/BaseSepoliaForkBase.sol`.

**`contracts/` appears as a submodule in `git status`.**
A stray `contracts/.git/` is the cause. Run `rm -rf contracts/.git`; then `git add contracts/` normally.

---

## 16. License

MIT. See `SPDX-License-Identifier` in each Solidity file.
