


# Notes
hardening_index=68

## Day 2 - SSH hardening
- Created a personal ed25519 key (lab_ed25519) and added it to authorized_keys (kept the AWS key)
- Created /etc/ssh/sshd_config.d/01-hardening.conf (content below)
- Safety net: systemd-run rollback timer (10 min), cancelled after a successful test
- Tests: key login OK, password login denied, root login denied
- Problem: "Could not resolve hostname pubkeyauthentication=no". The $KEY2 variable was empty
  in a new PowerShell window. Fix: define $IP and $KEY2 again in every new window.

### 01-hardening.conf
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowUsers ec2-user
ClientAliveInterval 300
ClientAliveCountMax 2

## Day 3 - firewalld and fail2ban

### firewalld
- Default zone: public, interface eth0
- Services before: cockpit dhcpv6-client ssh
- Removed cockpit (permanent). Services after: [ dhcpv6-client ssh]
- Runtime vs permanent test: [what happened to http after --reload  dhcpv6-client ssh, and after --permanent dhcpv6-client ssh http]


### fail2ban
- Config (/etc/fail2ban/jail.local): maxretry 5, findtime 10m, bantime 10m, sshd jail, backend systemd
- Ban test: 8 failed logins as fakeuser from my PC
- Result: [my ip was banned after 10 attempts]
- Unbanned with: fail2ban-client set sshd unbanip [my IP]

### Problems and fixes
- none
hardening_index=74
hardening_index=75

## Day 4: Automatic updates, sysctl, review, final Lynis

### dnf-automatic
- Installed dnf-automatic
- Set in /etc/dnf/automatic.conf: upgrade_type = default, apply_updates = yes
- Enabled dnf-automatic.timer, checked with systemctl list-timers
- Note: on CentOS Stream I used "default" because Stream has no security-classified updates

### sysctl hardening
- Created /etc/sysctl.d/99-hardening.conf (rp_filter, accept_redirects, send_redirects,
  accept_source_route, icmp_echo_ignore_broadcasts, tcp_syncookies, log_martians)
- Applied with sudo sysctl --system
- Verified: tcp_syncookies = 1, rp_filter = 1

### System review
- Open ports: 22 (sshd), chronyd local only
- Only root has UID 0
- No accounts without password hash
- /etc/shadow mode: ----------
- ~/.ssh is 700, authorized_keys is 600
- SELinux: Enforcing, ausearch -m avc: no matches
## Day 5: backup.sh and health_check.sh

### backup.sh
- Created ~/linux-hardening-lab/scripts/backup.sh, chmod +x
- Test: ./backup.sh -> "Backup created: ... (size)"
- Verified archive contents with tar -tzf: contains projects/test.txt
- Retention test: ran 10 times, ls ~/backups | wc -l -> 7

### health_check.sh
- Created health_check.sh, ran with sudo
- Result: uptime, disk X%, memory Y%, SELinux Enforcing, 4 services [OK]
- Alarm test: stopped fail2ban -> [FAIL] shown, started again -> [OK]
### What I learned
- set -euo pipefail stops the script on errors
- ${1:-default} gives a default value for arguments



## Day 6: cleanup_logs.sh + cron

### What I did
- Created cleanup_logs.sh (dry-run by default, deletes only with the word "delete") and tested it on files made with touch -d "30 days ago".
- Ran ShellCheck on all scripts.
- Scheduled 3 jobs in cron: backup 02:00 daily, health check 07:00 daily, log cleanup Sunday 03:30.
- Left the instance running overnight to prove the real schedule.

### Evidence
- backup.log shows the 02:00 job ran by itself (backup_20261012_020001.tar.gz).
- health.log shows the 07:00 job ran by itself (all services [OK], disk 10%, memory 20%).
- After fixing backup.sh, the retention test (10 runs in a loop) printed "Old backups cleaned (kept the newest 7)" and ls ~/backups | wc -l gave 7.

### Problems and how I solved them
1. rm: cannot remove '-' in backup.log
   - Cause: line 18 of backup.sh had "rm -" instead of "rm --".
   - Found it in the cron log, fixed it with nano, checked with grep -n "xargs".
2. unexpected EOF while looking for matching quote
   - Cause: the closing " was missing at the end of the last echo line.
   - Found it with tail -n 3 backup.sh | cat -A, checked with bash -n.
3. health.log said "SELinux tools not installed" although SELinux is Enforcing
   - Cause: cron runs with a short PATH that does not include /usr/sbin (where getenforce lives).
   - Fix: added a PATH line at the top of the crontab.
4. The crontab file got corrupted when pasting into nano (lines merged together)
   - Fix: wrote the whole file in one command with crontab - <<'EOF'.
   - Checked with crontab -l.

### Lessons
- A script that works by hand can fail in cron because cron has a minimal environment (PATH).
- Always read the cron log files; they show real errors.
- Use bash -n and shellcheck before trusting a script.

### Still to confirm (fill in tomorrow)
- health_check.sh from cron shows "Mode: Enforcing" after the PATH fix: ____
- backup.log from the 02:00 cron run shows "Old backups cleaned" without errors: ____

### Result (next morning, 13 Oct)
- health_check.sh from cron shows "Mode: Enforcing" after the PATH fix: YES (12 Oct report said "SELinux tools not installed", 13 Oct report says "Mode: Enforcing")
- backup.log from the 02:00 cron run (13 Oct) shows "Old backups cleaned" without errors: YES
