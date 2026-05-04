# Stash — A non-custodial USDC neobank for emerging markets

> The dollar bank that fits in your pocket — no bank account, no custodian, no minimum balance.

Stash is a non-custodial stablecoin neobank built on [Base](https://base.org). It gives anyone — starting with savers in Nigeria — programmable access to dollar-denominated savings and transfers through three immutable smart contracts. Funds never touch a Stash-controlled wallet; the user always holds the keys.

---

## Table of contents

1. [The problem](#1-the-problem)
2. [How Stash solves it](#2-how-stash-solves-it)
3. [Why Stash is different](#3-why-stash-is-different)
4. [Market opportunity](#4-market-opportunity)
5. [Validation & traction signals](#5-validation--traction-signals)
6. [Architecture](#6-architecture)
7. [Quick start](#7-quick-start)
8. [Deployed contracts](#8-deployed-contracts)
9. [Tech stack](#9-tech-stack)
10. [Security](#10-security)
11. [Roadmap](#11-roadmap)
12. [Contributing](#13-contributing)
13. [License](#14-license)

---

## 1. The problem

In emerging markets — especially West and East Africa, Latin America, and parts of South Asia — the financial system fails ordinary people in three load-bearing ways:

- **Currency depreciation eats savings.** The Nigerian Naira lost roughly **70% of its value** against the dollar between January 2023 and January 2025 (₦460 → ₦1,500+/USD). A teacher who saved ₦5M in cash in 2023 now has the purchasing power of ₦1.5M.
- **Dollar accounts are gated.** Domiciliary (USD-denominated) bank accounts in Nigeria require minimum balances most people can't meet, opaque KYC, and arbitrary withdrawal limits. The CBN restricts naira-funded dollar inflows. Most workers have no real path to USD.
- **The crypto alternative is unsafe.** Centralised exchanges have collapsed (FTX, Patricia in Nigeria, AfriCrypt) leaving users with no recourse. Self-custody is technically demanding: seed phrases, gas tokens, contract approvals, chain selection — every step is a place to lose money.

The combined effect: **150+ million working-age Nigerians, and ~1.4B people across emerging markets, want dollar savings and have no safe, accessible way to get them.**

## 2. How Stash solves it

Stash is a savings-first neobank where the underlying asset is **Circle's USDC stablecoin on Base**, not a bank deposit. Three primitives, all on-chain, all non-custodial:

- **Flexible vault (`svfUSDC`)** — instant-access USDC savings via an ERC-4626 vault. Deposit any amount, withdraw any time. On mainnet, deposits route into [Aave v3 on Base](https://aave.com) for protocol-level yield ([research](docs/yield-platforms-research.md)).
- **Fixed vault** — time-locked positions for 30, 60, or 90 days. The contract enforces the lock; not even Stash can unlock early. Like a digital "ajo" / cooperative savings, but with on-chain settlement.
- **P2P transfer** — send USDC directly to any wallet with an optional on-chain memo. Settles in seconds for less than a cent in gas.

Layered on top, three UX commitments:

- **Naira-first numbers.** Every USDC balance is shown alongside its real-time NGN-equivalent. Users see "₦1.5M saved" not "1,000.00 USDC". On the dashboard, Stash also shows the **Naira-denominated change since deposit** so users can see what currency depreciation has done to their effective purchasing power.
- **Bank-grade off-ramp.** Withdraw to a Nigerian bank account at the live market rate via [Yellow Card](https://yellowcard.io)'s NIBSS-instant rails.
- **No-ETH onboarding.** New users will never need to first acquire ETH for gas. Coinbase Smart Wallet + CDP Paymaster sponsors all deposits, withdrawals, and transfers up to a per-user limit.

## 3. Why Stash is different

| | Traditional banks (Nigeria) | CEXs (Binance, Bybit) | Self-custody DeFi | **Stash** |
|---|---|---|---|---|
| Custody of funds | Bank | Exchange | User | **User** |
| USD-denominated savings | Domiciliary (gated) | USDT/USDC (CEX-held) | Yes | **Yes** |
| Withdrawal to NGN bank | Yes (slow) | Indirect (P2P) | No | **Yes (instant)** |
| Time-locked savings | Yes (admin can break) | No | Possible (DIY) | **Yes (contract-enforced)** |
| Counterparty risk | High (CBN intervention, bank failures) | High (CEX collapse history) | Smart-contract risk only | **Smart-contract risk only** |
| Onboarding effort | Days, paperwork | Hours, exchange KYC | Minutes (with friction) | **Minutes (no ETH needed)** |
| Open-source code | No | No | Sometimes | **Yes (MIT)** |

**The single sentence**: Stash is the only product that combines Nigerian-bank-account-grade off-ramp with non-custodial DeFi savings and a UX that doesn't assume the user understands gas, chains, or seed phrases.

## 4. Market opportunity

> Numbers below are conservative public estimates from World Bank, McKinsey, Statista, Chainalysis (2023–2025). Assumptions are explicit so they can be challenged.

### TAM — Total Addressable Market

The global population of adults in countries that combine (a) significant currency depreciation/inflation and (b) crypto adoption traction. Per Chainalysis Global Crypto Adoption Index, ~21 markets with adoption scores above 0.3 fit. Combined adult population: **≈1.4 billion**. Average annual savings the platform could service (assume $200/yr per saver as deposit-not-flow): **~$280B AUM TAM**.

### SAM — Serviceable Addressable Market

Sub-Saharan Africa + Southeast Asia + LatAm where Stash's tech stack (Base, USDC, Yellow Card / Onramper rails) operates today. Adult population: **~600M**. Stablecoin-curious cohort (per Chainalysis: ~7% of adults are active in stablecoins): **~42M users**. At $500 average deposit per user: **~$21B AUM SAM**.

### SOM — Serviceable Obtainable Market (5 years)

Nigeria-first beachhead. Nigerian working-age adults ~115M, of whom ~33M are smartphone-banked ([Statista, 2024](https://www.statista.com/topics/8108/banking-in-nigeria/)). Nigeria has **the highest crypto adoption rate in Africa** by Chainalysis 2024 — top 2 globally. Realistic 5-year capture (~1% of smartphone-banked adults): **~330,000 users × $400 average deposit = ~$130M AUM**.

Revenue model (illustrative, not prescriptive):
- 0.50% AUM annual fee on yield-routed flexible deposits → ~$650K ARR at 5-year SOM
- 0.30% spread on fiat off-ramp → ~$300K ARR at moderate volume
- Optional premium tier ($2/month) for advanced features → bonus

These are **not** founder fantasies — they're the bottom-of-the-range scenarios. The opportunity is large enough to support a venture-scale outcome even at conservative capture rates.

## 5. Validation & traction signals

What we already know about demand:

- **Stablecoin volume out of Africa keeps growing.** Sub-Saharan Africa processes [~$117B in crypto value annually per Chainalysis](https://www.chainalysis.com/blog/sub-saharan-africa-crypto-adoption/), with Nigeria leading. Stablecoin share: ~43% of all African crypto transactions.
- **The naira/dollar gap is widening.** ₦460 (Jan 2023) → ₦1,540 (Jan 2025). Every month a Nigerian holds Naira savings is a month of measurable purchasing-power loss.
- **Existing competitors prove demand exists.** Yellow Card (~$3B annual volume), Bitnob, Risevest, Bamboo, Chipper Cash — all show users want USD exposure. None of them combines non-custodial savings + locked savings + off-ramp + Naira-first UX in one product.
- **Coinbase is leaning in.** The Coinbase × Yellow Card partnership (2024) explicitly settles USDC on Base for African users. This is the rail Stash uses too.

What we still need to validate:
- 30/60/90-day lock UX → does the 5–10% APY premium that yield protocols pay justify giving up access?
- Off-ramp friction → how often does a user need to withdraw to NGN vs. just hold USDC?
- Average deposit size → are users dipping in with $20 or committing $500?

These are the questions the MVP exists to answer.

## 6. Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                       USER (Anywhere i.e Lagos / Abuja)          │
│                  smartphone · MetaMask · Coinbase Wallet         │
└──────────────────────────────────────┬───────────────────────────┘
                                       │
                                  Wallet signs
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Stash Web App (Next.js 16)                    │
│   landing · dashboard · flexible · fixed · transfer · settings   │
│                ethers.js v6 + EIP-6963 wallet picker             │
│                Naira-equivalent stat · live FX rate              │
└──────────────────────────────────────┬───────────────────────────┘
                                       │
                              JSON-RPC + signed tx
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                          BASE  (chain 84532 / 8453)             │
│                                                                 │
│   ┌────────────────────┐  ┌────────────────────┐  ┌──────────┐  │
│   │   FlexibleVault    │  │     FixedVault     │  │ P2PTrans │  │
│   │   ERC-4626         │  │  positions[]       │  │ memo evt │  │
│   │   _decimalsOffset=6│  │  30/60/90d locks   │  │          │  │
│   │   nonReentrant     │  │  immutable unlockAt│  │          │  │
│   └─────────┬──────────┘  └─────────┬──────────┘  └─────┬────┘  │
│             │                       │                   │       │
│             └────── SafeERC20 ──────┴────── transferFrom ───────│
│                              │                                  │
│                    ┌─────────▼─────────┐                        │
│                    │   USDC (Circle)   │                        │
│                    └───────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘

  Future (mainnet):
   FlexibleVault deposits → routed to Aave v3 on Base for yield
   Withdraw button → Yellow Card NIBSS-instant payout to NGN bank
   Connect button → Coinbase Smart Wallet + CDP Paymaster (no ETH)
```

Three independent, immutable contracts. No proxy, no admin, no governance.

The frontend is a pure client app. **No backend, no database, no indexer.** All reads come from RPC; all history comes from `eth_getLogs`. Browser localStorage caches wallet selection and FX baselines. This minimizes attack surface and operating cost.

## 7. Quick start

```bash
# clone
git clone --recurse-submodules https://github.com/harystyleseze/stash.git
cd stash

# contracts (Foundry)
cd contracts
./scripts/install-oz.sh
forge build && forge test

# web app
cd ../web
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

To actually deposit / withdraw on Base Sepolia testnet you need:
1. A Web3 wallet (MetaMask, Coinbase Wallet, or anything announcing via [EIP-6963](https://eips.ethereum.org/EIPS/eip-6963)).
2. **Base Sepolia ETH** for gas — get some at any Base Sepolia faucet (try [Coinbase Faucet](https://portal.cdp.coinbase.com/products/faucet) or [QuickNode](https://faucet.quicknode.com/base/sepolia)).
3. **Base Sepolia USDC** — request up to 20 USDC at [Circle's testnet faucet](https://faucet.circle.com) (select "Base Sepolia").

When you click **Get started** on the landing page, Stash opens a wallet-selection modal listing every Web3 wallet your browser exposes. After connecting, you're auto-redirected to the dashboard.

### Environment

A single `.env.local` file (web/) is enough. Both variables are optional:

```bash
# web/.env.local — all optional
NEXT_PUBLIC_RPC_URL=https://base-sepolia.public.blastapi.io   # default fine
NEXT_PUBLIC_LOG_CHUNK_SIZE=999                                 # public RPCs limit getLogs to 1000 blocks
```

No project ID, no API keys, no wallet-vendor signups required.

## 8. Deployed contracts

**Network:** Base Sepolia (chain ID `84532`). Mainnet coming after audit.

| Contract | Address | Source verified |
|---|---|---|
| USDC (Circle-native) | [`0x036CbD53842c5426634e7929541eC2318f3dCF7e`](https://sepolia.basescan.org/address/0x036CbD53842c5426634e7929541eC2318f3dCF7e) | — |
| FlexibleVault (svfUSDC) | [`0x56fB93B19bBaF700A4a9214388d664d1A25A699E`](https://sepolia.basescan.org/address/0x56fB93B19bBaF700A4a9214388d664d1A25A699E) | ✅ |
| FixedVault | [`0xAc49f293D7b98119E45eCC4Fd528D480dea9F4A8`](https://sepolia.basescan.org/address/0xAc49f293D7b98119E45eCC4Fd528D480dea9F4A8) | ✅ |
| P2PTransfer | [`0x0C8d08a5d2e107b6f0F09025230C8458376062e7`](https://sepolia.basescan.org/address/0x0C8d08a5d2e107b6f0F09025230C8458376062e7) | ✅ |


## 9. Tech stack

### Smart contracts
- **Solidity** `0.8.26` · EVM `cancun` · optimizer 10,000 runs
- **Foundry** for build, test, fuzz, invariant, fork tests, and deployment scripts
- **OpenZeppelin Contracts** v5.1.0 (ERC-4626, ERC-20, SafeERC20, ReentrancyGuard)
- **forge-std** for cheats and test helpers

### Web app
- **Next.js 16** (App Router) on **React 19** with **TypeScript** strict mode
- **ethers.js v6** for chain interaction (no wagmi, no AppKit dependency)
- **EIP-6963** wallet discovery for multi-wallet picker (MetaMask, Coinbase Wallet, Brave, Rabby, etc.)
- Pure CSS / SCSS with CSS-variable-based light/dark theming via **next-themes**
- **lucide-react** icons; **react-icons** for select brand marks
- No backend, no database. All on-chain reads via JSON-RPC (`eth_call`, `eth_getLogs`)

## 10. Security

### Properties enforced by the contracts

- **Immutable**: no proxy, no upgrade mechanism, no `selfdestruct`, no `delegatecall` on user-facing surfaces.
- **No admin**: zero privileged roles. Nobody can pause, drain, or alter the contracts after deployment.
- **Reentrancy**: `ReentrancyGuard` on every state-changing entry point.
- **Safe ERC-20**: every token transfer goes through OpenZeppelin's `SafeERC20`.
- **ERC-4626 inflation attack** mitigated via `_decimalsOffset() = 6` plus a 1 USDC seed-burn at deploy.
- **Custom errors** for every revert path — exact failure mode is parsed and surfaced in the UI.

### Properties verified by tests

- Unit + fuzz coverage at **100% lines / 100% branches** for `FixedVault`, `FlexibleVault`, `P2PTransfer`, and the deploy script.
- **Invariant tests** (256 runs × 64 depth) confirm: vault balance ≥ open positions; total supply > 0 after seed-burn; locked positions are immutable until maturity; first-depositor inflation attack fails.
- **Fork tests** against the real Circle USDC on Base Sepolia.

## 11. Roadmap

### MVP (current — Base Sepolia)
- [x] Three immutable contracts deployed and verified
- [x] End-to-end frontend wired to real on-chain state (no mock data)
- [x] EIP-6963 wallet picker (MetaMask, Coinbase, Rabby, Brave, etc.)
- [x] Naira-equivalent balance with live FX rate
- [x] Per-position countdown timers + on-chain unlock enforcement
- [x] Tx history via `eth_getLogs` with BaseScan deep-links

### V1 — Mainnet launch
- [ ] External security audit (target: Spearbit or OpenZeppelin)
- [ ] Base mainnet deployment of FlexibleVault, FixedVault, P2PTransfer
- [ ] **Yield routing**: FlexibleVault deposits supply to Aave v3 USDC market on Base
- [ ] **Off-ramp**: Yellow Card integration for USDC → NGN bank (NIBSS instant)
- [ ] **Gasless onboarding**: CDP Paymaster + Coinbase Smart Wallet
- [ ] `depositWithPermit` — one-tx flow via ERC-2612 / EIP-3009

### V2 — Growth
- [ ] Second yield vault: Morpho MetaMorpho (drop-in ERC-4626)
- [ ] Recurring deposits via Coinbase Smart Wallet Spend Permissions
- [ ] On-ramp: NGN bank → USDC via Yellow Card / Onramper
- [ ] Multi-currency: GHS, KES, ZAR (Yellow Card already covers these)
- [ ] Native cNGN support once liquidity arrives

### V3 — Platform
- [ ] Stash Card (USDC-funded virtual debit card)
- [ ] Group savings ("ajo" cooperative — multi-sig vaults)
- [ ] Salary streaming (Sablier-style payroll for crypto-paid teams)

## 12. Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: fork → branch off `dev` → PR to `dev`. Never target `main` directly. Every PR runs `forge fmt --check`, `forge build`, `forge test`, `npm run build`, `npm run lint`.

## 13. License

MIT. See [`LICENSE`](LICENSE) and `SPDX-License-Identifier` headers in each Solidity
