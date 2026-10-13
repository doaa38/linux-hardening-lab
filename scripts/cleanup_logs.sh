#!/usr/bin/env bash
# cleanup_logs.sh - Delete old *.log files from a directory (dry-run by default)
# Usage: ./cleanup_logs.sh [log_dir] [days] [dry-run|delete]
set -euo pipefail
LOG_DIR="${1:-$HOME/logs}"
DAYS="${2:-14}"
MODE="${3:-dry-run}"
if [[ ! -d "$LOG_DIR" ]]; then
  echo "ERROR: $LOG_DIR does not exist" >&2
  exit 1
fi
echo "Searching $LOG_DIR for *.log files older than $DAYS days..."
mapfile -t OLD_FILES < <(find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS")
if (( ${#OLD_FILES[@]} == 0 )); then
  echo "Nothing to clean."
  exit 0
fi
for f in "${OLD_FILES[@]}"; do
  if [[ "$MODE" == "delete" ]]; then
    rm -- "$f"
    echo "Deleted: $f"
  else
    echo "[dry-run] would delete: $f"
  fi
done
echo "Found ${#OLD_FILES[@]} file(s). Mode: $MODE"
