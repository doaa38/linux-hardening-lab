#!/usr/bin/env bash
# health_check.sh - Quick server health report (CentOS / RHEL family)
# Usage: sudo ./health_check.sh
set -u
DISK_LIMIT=80
MEM_LIMIT=80
echo "===== Health Check: $(uname -n) - $(date '+%Y-%m-%d %H:%M:%S') ====="
echo
echo "--- Uptime ---"
uptime -p
echo
echo "--- Disk usage (/) ---"
DISK_USED=$(df / --output=pcent | tail -1 | tr -dc '0-9')
echo "Used: ${DISK_USED}%"
if (( DISK_USED >= DISK_LIMIT )); then
  echo "WARNING: disk usage is above ${DISK_LIMIT}%"
fi
echo
echo "--- Memory usage ---"
MEM_USED=$(free | awk '/^Mem:/ {printf "%d", $3/$2*100}')
echo "Used: ${MEM_USED}%"
if (( MEM_USED >= MEM_LIMIT )); then
  echo "WARNING: memory usage is above ${MEM_LIMIT}%"
fi
echo
echo "--- Load average (1, 5, 15 min) ---"
cut -d' ' -f1-3 /proc/loadavg
echo
echo "--- SELinux ---"
if command -v getenforce > /dev/null 2>&1; then
  MODE=$(getenforce)
  echo "Mode: $MODE"
  if [[ "$MODE" != "Enforcing" ]]; then
    echo "WARNING: SELinux is not in Enforcing mode"
  fi
else
  echo "SELinux tools not installed"
fi
echo
echo "--- Critical services ---"
for svc in sshd firewalld fail2ban crond; do
  if systemctl is-active --quiet "$svc"; then
    echo "[OK] $svc is running"
  else
    echo "[FAIL] $svc is NOT running"
  fi
done
echo
echo "--- Suspicious SSH attempts (last 24h) ---"
FAILED=$(journalctl -u sshd --since "24 hours ago" --no-pager 2>/dev/null \
  | grep -cE "Invalid user|Failed password" || true)
echo "Invalid-user / failed-password lines: $FAILED"
