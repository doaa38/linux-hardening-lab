#!/usr/bin/env bash
# backup.sh - Create a compressed backup of a directory and keep only the newest N backups
# Usage: ./backup.sh [source_dir] [backup_dir]
set -euo pipefail
SOURCE_DIR="${1:-$HOME/projects}"
BACKUP_DIR="${2:-$HOME/backups}"
KEEP=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="$BACKUP_DIR/backup_${TIMESTAMP}.tar.gz"
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "ERROR: source directory $SOURCE_DIR does not exist" >&2
  exit 1
fi
mkdir -p "$BACKUP_DIR"
tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
echo "Backup created: $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
# Remove old backups, keep the newest $KEEP
ls -1t "$BACKUP_DIR"/backup_*.tar.gz | tail -n +$((KEEP + 1)) | xargs -r rm --
echo "Old backups cleaned (kept the newest $KEEP)"
