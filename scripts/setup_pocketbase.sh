#!/usr/bin/env bash
# Downloads the pinned PocketBase binary for local development (macOS/Linux).
# Run from the repo root: bash scripts/setup_pocketbase.sh
set -euo pipefail

VERSION="0.40.4"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/pocketbase"
mkdir -p "$DEST/pb_migrations"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$OS" in
  linux*) OS="linux" ;;
  darwin*) OS="darwin" ;;
  *) echo "Unsupported OS: $OS (use scripts/setup_pocketbase.ps1 on Windows)"; exit 1 ;;
esac

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

ZIP_NAME="pocketbase_${VERSION}_${OS}_${ARCH}.zip"
URL="https://github.com/pocketbase/pocketbase/releases/download/v${VERSION}/${ZIP_NAME}"

echo "Downloading PocketBase v${VERSION} (${OS}/${ARCH}) ..."
curl -sL -o "$DEST/$ZIP_NAME" "$URL"
unzip -o "$DEST/$ZIP_NAME" pocketbase -d "$DEST"
rm "$DEST/$ZIP_NAME"
chmod +x "$DEST/pocketbase"

echo "PocketBase binary ready at $DEST/pocketbase"
echo ""
echo "Next steps:"
echo "  cd pocketbase"
echo "  ./pocketbase serve                # applies pb_migrations automatically"
echo "  ./pocketbase superuser upsert you@local.test YourPassword123!"
echo "  node ../scripts/seed_dev_data.mjs"
