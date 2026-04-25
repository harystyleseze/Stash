#!/usr/bin/env bash
# install-oz.sh — fetch OpenZeppelin Contracts 5.1.0 into contracts/lib/openzeppelin-contracts.
# Uses the tagged release tarball, which is more robust than `forge install` on flaky networks.

set -euo pipefail

OZ_VERSION="v5.1.0"
OZ_TARBALL="https://github.com/OpenZeppelin/openzeppelin-contracts/archive/refs/tags/${OZ_VERSION}.tar.gz"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIB_DIR="${REPO_ROOT}/contracts/lib"
TARGET="${LIB_DIR}/openzeppelin-contracts"

mkdir -p "${LIB_DIR}"
if [[ -d "${TARGET}" ]]; then
  echo "OpenZeppelin already installed at ${TARGET}. Skipping."
  exit 0
fi

TMP_TAR="$(mktemp -t oz.XXXXXX).tar.gz"
trap 'rm -f "${TMP_TAR}"' EXIT

echo "Downloading OpenZeppelin Contracts ${OZ_VERSION}..."
curl -fsSL "${OZ_TARBALL}" -o "${TMP_TAR}"

echo "Extracting..."
tar -xzf "${TMP_TAR}" -C "${LIB_DIR}"
mv "${LIB_DIR}/openzeppelin-contracts-${OZ_VERSION#v}" "${TARGET}"

echo "Done: ${TARGET}"
