# Stash

**Stash** is a non-custodial USDC savings app built on Base. It lets anyone hold USD savings on-chain without giving up custody — no bank account required, no counterparty holding your funds.

Three savings primitives, zero admin keys:

- **Flexible savings** — deposit USDC, receive vault shares, withdraw any time.
- **Fixed savings** — lock USDC for 30, 60, or 90 days. The contract enforces the lock; no one can bypass it, including the deployers.
- **P2P transfers** — send USDC to any address with an optional on-chain memo for payment history.

Targeted at users in economies with high inflation or limited access to USD financial products. The contracts are immutable, the vaults are non-custodial, and the code is fully open source.

---

## Repository layout

```
stash/
├── contracts/          Foundry workspace — all on-chain code
│   ├── src/            Production Solidity contracts
│   ├── script/         Deploy script (Foundry Solidity)
│   ├── scripts/        Shell helpers (install-oz, verify)
│   ├── test/           Unit · fuzz · fork · invariant tests
│   ├── foundry.toml    Compiler + RPC + Etherscan config
│   ├── README.md       Contracts-specific setup guide
│   └── ARCHITECTURE.md Full architecture + deployed addresses
│
├── web/                Next.js 16 app — frontend
│   ├── app/            App Router pages and layouts
│   ├── public/         Static assets
│   ├── next.config.ts
│   └── package.json
│
├── .github/
│   └── workflows/
│       └── test.yml    CI — forge fmt · build · test · coverage
│
├── README.md           This file
└── CONTRIBUTING.md     How to contribute
```

---

## How it works

### Smart contracts

Three immutable contracts deployed on Base Sepolia (testnet). All share one underlying asset: **Circle-native USDC**.

#### FlexibleVault — instant-access savings

Implements [ERC-4626](https://eips.ethereum.org/EIPS/eip-4626), the tokenised vault standard. Users deposit USDC and receive `svfUSDC` shares representing their proportional claim on the vault's total assets.

Key properties:
- `_decimalsOffset() = 6` combined with a 1 USDC seed-burn at deploy prevents the first-depositor inflation attack.
- `nonReentrant` on `deposit`, `mint`, `withdraw`, `redeem`.
- No admin, no pause, no proxy. Shares are redeemable at any time.

#### FixedVault — time-locked savings

Not ERC-4626. Each user holds an array of `Position` structs, one per deposit. Every position records an `amount`, an `unlockAt` timestamp, and a `withdrawn` flag — all packed into one 32-byte storage slot.

Key properties:
- Lock durations: **30 days**, **60 days**, or **90 days** — nothing else is accepted.
- `unlockAt` is written once at deposit time and never changes.
- `withdraw(positionId)` reverts with `NotYetUnlocked(unlockAt)` if called before maturity. There is no admin function to override this.
- `AlreadyWithdrawn` prevents double-spending.

#### P2PTransfer — USDC transfer with memo

A thin wrapper around USDC's `transferFrom`. Its only purpose is to emit `Sent(from, to, amount, memo)` — a structured, indexed event that the frontend uses to build a transaction history without a backend indexer.

Validation: non-zero address, non-self, non-zero amount, memo ≤ 256 bytes.

---

### Web app

Built with **Next.js 16** (App Router), **TypeScript**, **Tailwind CSS v4**, and **React 19**.

Chain interaction uses **wagmi v2** + **viem v2**. Wallet connection uses **RainbowKit** (MetaMask, Rabby, Rainbow, WalletConnect). No Privy, no paymaster, no account abstraction — plain EOA wallets.

All on-chain reads are done directly via RPC:
- User USDC balance and flexible vault balance via `multicall`.
- Fixed vault positions via `FixedVault.getPositions(user)`.
- Transaction history via `getLogs` on `Deposit`/`Withdraw`/`PositionOpened`/`PositionClosed`/`Sent` events, filtered to the connected address.

No backend server, no indexer, no database. Everything is read from the chain or cached in the browser.

---

### Contract ↔ frontend integration

The frontend talks to the contracts through three ABIs generated from the compiled artifacts:

```
contracts/out/FlexibleVault.sol/FlexibleVault.json   → web/lib/abi/FlexibleVault.json
contracts/out/FixedVault.sol/FixedVault.json         → web/lib/abi/FixedVault.json
contracts/out/P2PTransfer.sol/P2PTransfer.json       → web/lib/abi/P2PTransfer.json
```

Contract addresses are hard-coded in `web/lib/addresses.ts` per chain:

```ts
export const ADDRESSES = {
  baseSepolia: {
    usdc:          '0x036CbD53842c5426634e7929541eC2318f3dCF7e',
    flexibleVault: '0x56fB93B19bBaF700A4a9214388d664d1A25A699E',
    fixedVault:    '0xAc49f293D7b98119E45eCC4Fd528D480dea9F4A8',
    p2pTransfer:   '0x0C8d08a5d2e107b6f0F09025230C8458376062e7',
  },
} as const
```

Every deposit requires a two-step flow: `USDC.approve(vault, amount)` → `vault.deposit(amount, ...)`. This is a known UX gap — `permit`-based one-step deposits are on the roadmap.

---

## Deployed contracts — Base Sepolia

| Contract | Address | Explorer |
|---|---|---|
| USDC (Circle-native) | `0x036CbD53842c5426634e7929541eC2318f3dCF7e` | [BaseScan](https://sepolia.basescan.org/address/0x036CbD53842c5426634e7929541eC2318f3dCF7e) |
| FlexibleVault | `0x56fB93B19bBaF700A4a9214388d664d1A25A699E` | [BaseScan ✅](https://sepolia.basescan.org/address/0x56fB93B19bBaF700A4a9214388d664d1A25A699E) |
| FixedVault | `0xAc49f293D7b98119E45eCC4Fd528D480dea9F4A8` | [BaseScan ✅](https://sepolia.basescan.org/address/0xAc49f293D7b98119E45eCC4Fd528D480dea9F4A8) |
| P2PTransfer | `0x0C8d08a5d2e107b6f0F09025230C8458376062e7` | [BaseScan ✅](https://sepolia.basescan.org/address/0x0C8d08a5d2e107b6f0F09025230C8458376062e7) |

All three contracts are source-verified. See [`contracts/ARCHITECTURE.md`](contracts/ARCHITECTURE.md) for deployment transaction hashes, constructor arguments, gas used, and full contract reference.

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| **Foundry** (`forge`, `cast`) | latest stable | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| **Node.js** | 20 LTS | [nodejs.org](https://nodejs.org) |
| **npm** | 10+ | bundled with Node |
| **git** | 2.30+ | OS package |
| **jq** | 1.6+ | `brew install jq` |

---

## Getting started

### 1. Clone

```bash
git clone --recurse-submodules https://github.com/harystyleseze/stash.git
cd stash
```

`--recurse-submodules` pulls `forge-std`. If you forgot: `git submodule update --init --recursive`.

### 2. Contracts

```bash
cd contracts
./scripts/install-oz.sh   # downloads OZ Contracts 5.1.0 (idempotent)
forge build               # compile
forge test                # run tests
```

Expected: `85 tests passed, 0 failed, 8 skipped` (skipped = fork tests that need a live RPC).

To run fork tests against real USDC on Base Sepolia:

```bash
export BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
forge test --match-path 'test/fork/*.base-sepolia.fork.t.sol' -vv
```

### 3. Web app

```bash
cd web
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

To connect to the testnet contracts you need a wallet configured for **Base Sepolia** (chain ID `84532`) and some Base Sepolia ETH (for gas). Testnet USDC from [Circle's faucet](https://faucet.circle.com) — select Base Sepolia and request up to 20 USDC.

---

## Environment variables

### Contracts (`contracts/.env`)

Copy the template and fill in your values:

```bash
cp contracts/.env.example contracts/.env
```

| Variable | Required for | Description |
|---|---|---|
| `PRIVATE_KEY` | Deploy, verify | Deploy wallet private key. Never commit. |
| `ETHERSCAN_API_KEY` | Verify | Etherscan V2 key — one key covers all supported chains. Free at [etherscan.io/myapikey](https://etherscan.io/myapikey). |
| `BASE_SEPOLIA_RPC_URL` | Fork tests, deploy | Defaults to `https://sepolia.base.org` if not set. |
| `BASE_MAINNET_RPC_URL` | Fork tests (mainnet) | Only needed for Base mainnet fork tests. |
| `USDC_ADDRESS` | Deploy | Circle USDC address for the target chain. |

### Web (`web/.env.local`)

```bash
NEXT_PUBLIC_CHAIN_ID=84532                        # Base Sepolia
NEXT_PUBLIC_RPC_URL=https://sepolia.base.org
```

---

## Deploying the contracts

Full step-by-step in [`contracts/README.md`](contracts/README.md). Short version:

```bash
cd contracts
set -a; source .env; set +a

forge script script/Deploy.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

After deploy, verify on BaseScan:

```bash
CHAIN=base-sepolia \
USDC_ADDRESS=0x036CbD53842c5426634e7929541eC2318f3dCF7e \
FLEXIBLE_VAULT=0x<addr> \
FIXED_VAULT=0x<addr> \
P2P_TRANSFER=0x<addr> \
ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY \
./scripts/verify.sh
```

---

## Testing

### Contracts

```bash
cd contracts

forge test                                         # all unit + fuzz + invariant + script tests
forge test -vvv                                    # verbose
forge test --match-contract FlexibleVault          # one suite
forge coverage --no-match-path 'test/fork/*' \
  --report summary                                 # coverage report
```

CI runs on every push and pull request via `.github/workflows/test.yml` — format check, build, full test suite, coverage.

### Web

```bash
cd web
npm run lint     # ESLint
npm run build    # production build smoke test
```

---

## CI

GitHub Actions (`.github/workflows/test.yml`) runs on every push and PR:

1. `forge fmt --check` — code is formatted
2. `forge build --sizes` — compiles cleanly, prints bytecode sizes
3. `forge test -vvv` — all tests pass (fork tests skip gracefully without RPC env vars)
4. `forge coverage --report summary` — coverage report printed to log

---

## Architecture

Full smart contract architecture, storage layouts, transaction flow diagrams, and security properties are documented in [`contracts/ARCHITECTURE.md`](contracts/ARCHITECTURE.md).

---

## Security

- Contracts are **immutable** — no proxy, no upgrade mechanism.
- No admin roles — no address can pause, drain, or alter the contracts.
- ERC-4626 inflation attack mitigated via `_decimalsOffset = 6` + 1 USDC seed-burn.
- All state-changing functions protected with `ReentrancyGuard`.
- All token transfers use OpenZeppelin `SafeERC20`.
- Verified by property-based invariant testing (256 runs × 64 depth).

The contracts have **not been audited**. Do not deploy to mainnet with real user funds before an independent audit.

If you find a security issue, please report it privately before disclosing publicly.

---

## Roadmap

- [ ] `depositWithPermit` — one-transaction deposits via ERC-2612 / EIP-3009
- [ ] `getOpenPositions` view helper on `FixedVault`
- [ ] Atomic seed-burn in deploy (factory / `CREATE2`)
- [ ] Base mainnet deployment
- [ ] Independent security audit
- [ ] cNGN support (Phase 2)
- [ ] Yield routing to Morpho / Aave (Phase 3)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow. Short version: fork → branch off `dev` → PR to `dev`. Never target `main` directly.

---

## License

MIT. See `SPDX-License-Identifier` headers in each Solidity file.
