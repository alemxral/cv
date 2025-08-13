#!/bin/bash

LOGFILE="/var/log/test.log"
CHECKLIST=()

log() {
  echo "$1" >> "$LOGFILE"
}

check() {
  local description="$1"
  local result="$2"
  local extra="$3"
  if [ "$result" = "OK" ]; then
    CHECKLIST+=("[PASS] $description")
    log "[PASS] $description $extra"
  else
    CHECKLIST+=("[FAIL] $description")
    log "[FAIL] $description $extra"
  fi
}

echo "===== Born2beRoot VM Automated Setup Test =====" > "$LOGFILE"
log "Date: $(date)"
log "User: $(whoami)"
log ""

# 1. LVM and encrypted partitions
lvm_count=$(lsblk -o TYPE | grep -c lvm)
crypt_count=$(lsblk -o TYPE | grep -c crypt)
desc="At least 2 LVM and 2 encrypted partitions exist"
if [ "$lvm_count" -ge 2 ] && [ "$crypt_count" -ge 2 ]; then
  check "$desc" OK "LVM=$lvm_count, crypt=$crypt_count"
else
  check "$desc" FAIL "LVM=$lvm_count, crypt=$crypt_count"
fi

# 2. Hostname
hostname_val=$(hostname)
desc="Hostname ends with 42"
if [[ "$hostname_val" =~ 42$ ]]; then
  check "$desc" OK "hostname=$hostname_val"
else
  check "$desc" FAIL "hostname=$hostname_val"
fi

# 3. UFW firewall
ufw_status=$(ufw status | grep Status 2>&1)
open_ports=$(ufw status | grep "4242" | grep ALLOW 2>&1)
desc="UFW active and port 4242 open"
if [[ "$ufw_status" == *"active"* ]] && [[ "$open_ports" != "" ]]; then
  check "$desc" OK "$ufw_status, port 4242 open"
else
  check "$desc" FAIL "$ufw_status, port 4242 not open"
fi

# 4. SSH config
sshd_port=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}' 2>&1)
permit_root=$(grep "^PermitRootLogin " /etc/ssh/sshd_config | awk '{print $2}' 2>&1)
desc="SSH runs on port 4242 and root login disabled"
if [ "$sshd_port" = "4242" ] && [[ "$permit_root" =~ "no" ]]; then
  check "$desc" OK "Port=$sshd_port, PermitRootLogin=$permit_root"
else
  check "$desc" FAIL "Port=$sshd_port, PermitRootLogin=$permit_root"
fi

# 5. User and groups
login42="$USER"
user_check=$(getent passwd "$login42")
group_check=$(groups "$login42" | grep user42)
sudo_check=$(groups "$login42" | grep sudo)
desc="User '$login42' exists"
check "$desc" $( [ -n "$user_check" ] && echo OK || echo FAIL ) "user_check=$user_check"
desc="User belongs to user42 group"
check "$desc" $( [ -n "$group_check" ] && echo OK || echo FAIL ) "group_check=$group_check"
desc="User belongs to sudo group"
check "$desc" $( [ -n "$sudo_check" ] && echo OK || echo FAIL ) "sudo_check=$sudo_check"

# 6. Password Policy
desc="Password expiration set to 30 days"
max_days=$(grep "PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
check "$desc" $( [ "$max_days" -eq 30 ] && echo OK || echo FAIL ) "PASS_MAX_DAYS=$max_days"

desc="Password minimum change interval set to 2 days"
min_days=$(grep "PASS_MIN_DAYS" /etc/login.defs | awk '{print $2}')
check "$desc" $( [ "$min_days" -eq 2 ] && echo OK || echo FAIL ) "PASS_MIN_DAYS=$min_days"

desc="Password expiration warning set to 7 days"
warn_age=$(grep "PASS_WARN_AGE" /etc/login.defs | awk '{print $2}')
check "$desc" $( [ "$warn_age" -eq 7 ] && echo OK || echo FAIL ) "PASS_WARN_AGE=$warn_age"

desc="Password minlen at least 10"
minlen=$(grep "minlen" /etc/security/pwquality.conf | awk '{print $3}')
check "$desc" $( [ "$minlen" -ge 10 ] && echo OK || echo FAIL ) "minlen=$minlen"

desc="Password contains uppercase, lowercase, digit, no more than 3 consecutive identical, not username"
pwquality_conf=$(cat /etc/security/pwquality.conf 2>&1)
rules_ok=$(echo "$pwquality_conf" | grep -E "ucredit|lcredit|dcredit|maxrepeat|usercheck")
check "$desc" $( [ -n "$rules_ok" ] && echo OK || echo FAIL ) "pwquality.conf=$pwquality_conf"

# 7. Sudo configuration
desc="Sudo limited to 3 authentication attempts"
sudo_attempts=$(grep "passwd_tries" /etc/sudoers | awk '{print $2}')
check "$desc" $( [ "$sudo_attempts" -eq 3 ] && echo OK || echo FAIL ) "passwd_tries=$sudo_attempts"

desc="Custom bad password message for sudo"
sudo_message=$(grep "badpass_message" /etc/sudoers)
check "$desc" $( [ -n "$sudo_message" ] && echo OK || echo FAIL ) "badpass_message=$sudo_message"

desc="Sudo logs archived in /var/log/sudo/"
sudo_log=$(grep "logfile" /etc/sudoers | grep "/var/log/sudo/")
check "$desc" $( [ -n "$sudo_log" ] && echo OK || echo FAIL ) "logfile=$sudo_log"

desc="Sudo TTY mode enabled"
sudo_tty=$(grep "requiretty" /etc/sudoers)
check "$desc" $( [ -n "$sudo_tty" ] && echo OK || echo FAIL ) "requiretty=$sudo_tty"

desc="Sudo secure_path restricted"
sudo_secure_path=$(grep "secure_path" /etc/sudoers)
check "$desc" $( [ -n "$sudo_secure_path" ] && echo OK || echo FAIL ) "secure_path=$sudo_secure_path"

# 8. Monitoring script
desc="monitoring.sh present in /usr/local/bin"
script_path="/usr/local/bin/monitoring.sh"
check "$desc" $( [ -f "$script_path" ] && echo OK || echo FAIL ) "$script_path"

desc="monitoring.sh in crontab"
crontab_monitor=$(crontab -l 2>/dev/null | grep monitoring.sh)
check "$desc" $( [ -n "$crontab_monitor" ] && echo OK || echo FAIL ) "crontab_monitor=$crontab_monitor"

desc="monitoring-banner systemd service enabled"
systemd_monitor=$(systemctl list-unit-files | grep monitoring-banner | grep enabled)
check "$desc" $( [ -n "$systemd_monitor" ] && echo OK || echo FAIL ) "systemd_monitor=$systemd_monitor"

desc="monitoring.sh runs without errors"
script_test=$(bash /usr/local/bin/monitoring.sh 2>&1 | grep -i error)
check "$desc" $( [ -z "$script_test" ] && echo OK || echo FAIL ) "script_test=$script_test"

# Print checklist to console
echo "===== Born2beRoot VM Test Checklist ====="
for item in "${CHECKLIST[@]}"; do
  echo "$item"
done
echo "Detailed logs: $LOGFILE"
