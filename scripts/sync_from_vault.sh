#!/usr/bin/env bash
set -euo pipefail

VAULT="/home/dahmakeit/Documents/Obsidian/Sado"
CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)/content"

mkdir -p "$CONTENT_DIR"

# Clean generated content, keep repo metadata files if any
find "$CONTENT_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    rsync -a "$src" "$dst"
  fi
}

# Allowlist
copy_if_exists "$VAULT/Home.md" "$CONTENT_DIR/Home.md"
copy_if_exists "$VAULT/Tea/" "$CONTENT_DIR/Tea/"
copy_if_exists "$VAULT/Weather/Tokyo/" "$CONTENT_DIR/Weather/Tokyo/"
copy_if_exists "$VAULT/Stocks/Buzzing/" "$CONTENT_DIR/Stocks/Buzzing/"
copy_if_exists "$VAULT/Books/Daily/" "$CONTENT_DIR/Books/Daily/"
copy_if_exists "$VAULT/Sources/Daily-5/" "$CONTENT_DIR/Sources/Daily-5/"

echo "Synced allowlisted notes from vault to Quartz content/."