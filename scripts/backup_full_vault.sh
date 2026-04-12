#!/usr/bin/env bash
set -euo pipefail

VAULT="/home/dahmakeit/Documents/Obsidian/Sado"
OUT_DIR="/home/dahmakeit/.openclaw/workspace/backups/sado-full"
STAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
ARCHIVE="$OUT_DIR/sado-full-${STAMP}.tar.zst"
LATEST="$OUT_DIR/latest.tar.zst"

mkdir -p "$OUT_DIR"

# Full private backup (no publish, no git push)
tar --zstd -cf "$ARCHIVE" -C "$(dirname "$VAULT")" "$(basename "$VAULT")"
ln -sfn "$(basename "$ARCHIVE")" "$LATEST"

# Retention: keep last 30 days
find "$OUT_DIR" -type f -name 'sado-full-*.tar.zst' -mtime +30 -delete

echo "Backup created: $ARCHIVE"
