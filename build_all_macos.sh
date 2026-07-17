#!/usr/bin/env bash
# Cross-compile rtk for macOS (aarch64, native) and Linux (aarch64, x86_64) using
# cargo-zigbuild, then package each binary as a versioned tar.gz in release/.
#
# Requirements:
#   brew install zig
#   cargo install cargo-zigbuild
#   rustup target add aarch64-apple-darwin x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu
set -euo pipefail

cd "$(dirname "$0")/.."

BIN_NAME="rtk"
RELEASE_DIR="release"
VERSION="$(cargo metadata --no-deps --format-version 1 | grep -o '"version":"[^"]*"' | head -n1 | cut -d'"' -f4)"

if [[ -z "${VERSION}" ]]; then
  echo "error: could not determine version from Cargo.toml" >&2
  exit 1
fi

echo "Building ${BIN_NAME} v${VERSION}"

# target-triple:os-arch-label pairs
TARGETS=(
  "aarch64-apple-darwin:macos-aarch64"
  "aarch64-unknown-linux-gnu:linux-aarch64"
  "x86_64-unknown-linux-gnu:linux-x86_64"
)

mkdir -p "${RELEASE_DIR}"

for entry in "${TARGETS[@]}"; do
  target="${entry%%:*}"
  label="${entry##*:}"

  echo ""
  echo "==> Building for ${target} (${label})"
  rustup target add "${target}" >/dev/null

  if [[ "${target}" == "aarch64-apple-darwin" ]]; then
    # Native target: plain cargo build (no zig needed)
    cargo build --release --target "${target}"
  else
    cargo zigbuild --release --target "${target}"
  fi

  bin_path="target/${target}/release/${BIN_NAME}"
  if [[ ! -f "${bin_path}" ]]; then
    echo "error: expected binary not found at ${bin_path}" >&2
    exit 1
  fi

  archive_name="${BIN_NAME}-v${VERSION}-${label}.tar.gz"
  archive_path="${RELEASE_DIR}/${archive_name}"

  echo "==> Packaging ${archive_path}"
  tar -czf "${archive_path}" -C "target/${target}/release" "${BIN_NAME}"

  echo "==> Done: ${archive_path}"
done

echo ""
echo "All archives written to ${RELEASE_DIR}/:"
ls -lh "${RELEASE_DIR}"/*.tar.gz