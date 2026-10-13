# Linux Hardening Lab

Hands-on lab where I secured a CentOS Stream 9 server on AWS EC2 and automated routine administration with Bash scripts.

## What I did
- **Infrastructure:** EC2 t3.micro, security group allowing SSH from my IP only, AMI backups, budget alert to control cost
- **SSH hardening:** key-based authentication only, root and password login disabled, AllowUsers, MaxAuthTries
- **Firewall:** firewalld with only the SSH service allowed (second layer behind the AWS security group)
- **Intrusion prevention:** fail2ban for SSH (5 failed attempts = 10 minute ban), tested and unbanned manually
- **Patching:** automatic updates with dnf-automatic
- **Kernel hardening:** network sysctl parameters (rp_filter, syncookies, redirects off)
- **Mandatory access control:** SELinux kept in Enforcing mode; fixed file labels with restorecon instead of disabling it
- **Measured with Lynis:** hardening index went from 68 to 75

## Bash scripts (`scripts/`)
| Script | Purpose |
|---|---|
| `backup.sh` | Compressed backup of a directory, keeps the newest 7 |
| `health_check.sh` | Reports disk, memory, load, SELinux, services, suspicious SSH attempts |
| `cleanup_logs.sh` | Removes old log files, dry-run by default |

All three are scheduled with cron and checked with ShellCheck.

## Configuration files (`configs/`)
SSH, fail2ban, sysctl, dnf-automatic settings and the firewalld zone used in the lab.

## Screenshots (`screenshots/`)
Lynis before/after, SSH tests, firewalld status, fail2ban ban, script output, cron logs.

## Challenges and what I learned
- **`rm: cannot remove '-'` in the cron log:** line 18 of backup.sh had `rm -` instead of `rm --`. I found it in backup.log, fixed it, and confirmed the next 02:00 cron run printed "Old backups cleaned" with no error.
- **Missing closing quote in backup.sh:** bash reported "unexpected EOF". I found it with `cat -A` and checked the fix with `bash -n`.
- **Script worked by hand but not from cron:** health.log said "SELinux tools not installed" although SELinux was Enforcing. Cron runs with a short PATH that does not include /usr/sbin, where getenforce lives. I added a PATH line to the crontab, and the next 07:00 run showed "Mode: Enforcing".
- **Corrupted crontab from pasting into an editor:** lines were merged together. I wrote the whole file in one command with `crontab - <<'EOF'` and checked it with `crontab -l`.

## Tools
AWS EC2, CentOS Stream 9, OpenSSH, firewalld, fail2ban, SELinux, Lynis, Bash, cron, Git
