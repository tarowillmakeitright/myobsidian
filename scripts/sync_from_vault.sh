#!/usr/bin/env bash
set -euo pipefail

VAULT="/home/dahmakeit/Documents/Obsidian/Sado"
CONTENT_DIR="$(cd "$(dirname "$0")/.." && pwd)/content"

mkdir -p "$CONTENT_DIR"

# Clean generated content
find "$CONTENT_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    rsync -a "$src" "$dst"
  fi
}

# Backup/publish scope
copy_if_exists "$VAULT/Home.md" "$CONTENT_DIR/Home.md"
copy_if_exists "$VAULT/Tea/" "$CONTENT_DIR/Tea/"
copy_if_exists "$VAULT/Weather/Tokyo/" "$CONTENT_DIR/Weather/Tokyo/"
copy_if_exists "$VAULT/Stocks/Buzzing/" "$CONTENT_DIR/Stocks/Buzzing/"
copy_if_exists "$VAULT/Books/Daily/" "$CONTENT_DIR/Books/Daily/"
copy_if_exists "$VAULT/Learning/" "$CONTENT_DIR/Learning/"
copy_if_exists "$VAULT/Markets/" "$CONTENT_DIR/Markets/"
copy_if_exists "$VAULT/Signals/" "$CONTENT_DIR/Signals/"
copy_if_exists "$VAULT/News/Nikkei/" "$CONTENT_DIR/News/Nikkei/"
copy_if_exists "$VAULT/Deals/AmazonJP/" "$CONTENT_DIR/Deals/AmazonJP/"

echo "Synced selected notes from vault to Quartz content/."
