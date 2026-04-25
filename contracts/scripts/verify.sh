#!/usr/bin/env bash
# verify.sh — verify Stash contracts on BaseScan (default) or Blockscout so the source becomes
# visible on the block explorer.
#
# Prerequisites:
#   - `forge` and `cast` on PATH (Foundry).
#   - Contracts already deployed.
#   - ETHERSCAN_API_KEY set when VERIFIER=etherscan (default). A single Etherscan V2 key works
#     across Base + Base Sepolia + 60 other chains. Register free at
#     https://etherscan.io/myapikey .  Blockscout mode (VERIFIER=blockscout) needs no key.
#
# Usage:
#   CHAIN=base-sepolia \
#   USDC_ADDRESS=0x036CbD53842c5426634e7929541eC2318f3dCF7e \
#   FLEXIBLE_VAULT=0x... \
#   FIXED_VAULT=0x... \
#   P2P_TRANSFER=0x... \
#   ETHERSCAN_API_KEY=... \
#   ./scripts/verify.sh
#
# Supported CHAIN values:
#   base-sepolia  → chain 84532, https://sepolia.basescan.org  (default)
#   base-mainnet  → chain 8453,  https://basescan.org
#
# Optional:
#   VERIFIER=etherscan   (default)  → BaseScan via Etherscan V2 unified API.
#   VERIFIER=blockscout              → Base Blockscout instance. No API key needed.

set -euo pipefail

CHAIN="${CHAIN:-base-sepolia}"
VERIFIER="${VERIFIER:-etherscan}"

case "$CHAIN" in
  base-sepolia)
    CHAIN_ID=84532
    RPC_URL_DEFAULT="https://sepolia.base.org"
    BASESCAN_EXPLORER="https://sepolia.basescan.org"
    BLOCKSCOUT_URL="https://base-sepolia.blockscout.com/api/"
    ;;
  base-mainnet)
    CHAIN_ID=8453
    RPC_URL_DEFAULT="https://mainnet.base.org"
    BASESCAN_EXPLORER="https://basescan.org"
    BLOCKSCOUT_URL="https://base.blockscout.com/api/"
    ;;
  *)
    echo "Unknown CHAIN='$CHAIN'. Use base-sepolia or base-mainnet." >&2
    exit 1
    ;;
esac

RPC_URL="${RPC_URL:-$RPC_URL_DEFAULT}"

# Etherscan V2 requires ?chainid= in the URL; --chain alone is not sufficient.
ETHERSCAN_V2_URL="https://api.etherscan.io/v2/api?chainid=$CHAIN_ID"

: "${USDC_ADDRESS:?USDC_ADDRESS not set (underlying asset the vaults use)}"
: "${FLEXIBLE_VAULT:?FLEXIBLE_VAULT not set}"
: "${FIXED_VAULT:?FIXED_VAULT not set}"
: "${P2P_TRANSFER:?P2P_TRANSFER not set}"

if [[ "$VERIFIER" == "etherscan" ]]; then
  : "${ETHERSCAN_API_KEY:?ETHERSCAN_API_KEY not set. Register at https://etherscan.io/myapikey (free; one V2 key covers all supported chains).}"
fi

echo "======================================================"
echo "  Stash — block-explorer verification"
echo "======================================================"
echo "Chain              : $CHAIN (id $CHAIN_ID)"
echo "Verifier           : $VERIFIER"
echo "RPC URL            : $RPC_URL"
if [[ "$VERIFIER" == "etherscan" ]]; then
  echo "Verifier URL       : $ETHERSCAN_V2_URL  (V2 unified)"
else
  echo "Verifier URL       : $BLOCKSCOUT_URL"
fi
echo "USDC address       : $USDC_ADDRESS"
echo "FlexibleVault      : $FLEXIBLE_VAULT"
echo "FixedVault         : $FIXED_VAULT"
echo "P2PTransfer        : $P2P_TRANSFER"
echo ""

verify_contract() {
  local address="$1"
  local contract_path="$2"
  local ctor_args="$3"

  echo "--- Verifying $contract_path at $address ---"
  local args=(
    --rpc-url "$RPC_URL"
    --chain "$CHAIN_ID"
    --watch
    "$address"
    "$contract_path"
  )

  if [[ "$VERIFIER" == "etherscan" ]]; then
    args+=(
      --verifier etherscan
      --verifier-url "$ETHERSCAN_V2_URL"
      --etherscan-api-key "$ETHERSCAN_API_KEY"
    )
  else
    args+=(
      --verifier blockscout
      --verifier-url "$BLOCKSCOUT_URL"
    )
  fi

  if [[ -n "$ctor_args" ]]; then
    args+=(--constructor-args "$ctor_args")
  fi

  forge verify-contract "${args[@]}"
  echo ""
}

# Constructor ABI encodings
FLEX_CTOR=$(cast abi-encode "constructor(address,string,string)" \
  "$USDC_ADDRESS" "Stash Flexible USDC" "svfUSDC")
FIXED_CTOR=$(cast abi-encode "constructor(address)" "$USDC_ADDRESS")
P2P_CTOR=$(cast abi-encode "constructor(address)" "$USDC_ADDRESS")

# Run from the Foundry workspace root so relative src/... paths resolve.
cd "$(dirname "$0")/.."

verify_contract "$FLEXIBLE_VAULT"  "src/FlexibleVault.sol:FlexibleVault" "$FLEX_CTOR"
verify_contract "$FIXED_VAULT"     "src/FixedVault.sol:FixedVault"       "$FIXED_CTOR"
verify_contract "$P2P_TRANSFER"    "src/P2PTransfer.sol:P2PTransfer"     "$P2P_CTOR"

echo "======================================================"
echo "  Verification requests submitted."
echo "  Open the explorer to confirm green checks:"
echo "    $BASESCAN_EXPLORER/address/$FLEXIBLE_VAULT"
echo "    $BASESCAN_EXPLORER/address/$FIXED_VAULT"
echo "    $BASESCAN_EXPLORER/address/$P2P_TRANSFER"
echo "======================================================"
