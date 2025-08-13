#!/bin/bash

echo "===== Born2beRoot VM Automated Setup Test ====="

echo ""
echo "[1] Checking for LVM and encrypted partitions:"
lvm_count=$(lsblk -o TYPE | grep -c lvm)
crypt_count=$(lsblk -o TYPE | grep -c crypt)
echo "  - LVM volumes found: $lvm_count"
echo "  - Encrypted partitions found: $crypt_count"
if [ "$lvm_count" -ge 2 ] && [ "$crypt_count" -ge 2 ]; then
  echo "  => OK: At least 2 encrypted LVM partitions found."
else
  echo "  => ERROR: Need at least 2 encrypted LVM partitions."
fi

echo ""
echo "[2] Hostname check:"
hostnamectl | grep hostname
if [[ "$(hostname)" =~ 42$ ]]; then
  echo "  => OK: Hostname ends with 42."
else
  echo "  => ERROR: Hostname does not end with 42."
fi

echo ""
echo "[3] UFW firewall (Debian):"
ufw_status=$(ufw status | grep Status)
echo "  - $ufw_status"
open_ports=$(ufw status | grep "4242" | grep ALLOW)
if [[ "$ufw_status" == *"active"* ]] && [[ "$open_ports" != "" ]]; then
  echo "  => OK: UFW active and port 4242 open."
else
  echo "  => ERROR: UFW not active or port 4242 not open."
fi

echo ""
echo "[4] SSH config:"
sshd_port=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')
permit_root=$(grep "^PermitRootLogin " /etc/ssh/sshd_config | awk '{print $2}')
echo "  - SSH Port: $sshd_port"
echo "  - PermitRootLogin: $permit_root"
if [ "$sshd_port" = "4242" ] && [[ "$permit_root" =~ "no" ]]; then
  echo "  => OK: SSH runs on 4242 and root login is disabled."
else
  echo "  => ERROR: SSH port/root login not correctly configured."
fi

echo ""
echo "[5] User and group checks:"
login42=$(whoami)
user_check=$(getent passwd "$login42")
group_check=$(groups "$login42" | grep user42)
sudo_check=$(groups "$login42" | grep sudo)
echo "  - User '$login42' exists: $( [ -n "$user_check" ] && echo OK || echo ERROR )"
echo "  - Belongs to user42 group: $( [ -n "$group_check" ] && echo OK || echo ERROR )"
echo "  - Belongs to sudo group: $( [ -n "$sudo_check" ] && echo OK || echo ERROR )"

echo ""
echo "[6] Password Policy:"
echo "  - Checking /etc/login.defs and /etc/pam.d/common-password..."
grep "PASS_MAX_DAYS" /etc/login.defs
grep "PASS_MIN_DAYS" /etc/login.defs
grep "PASS_WARN_AGE" /etc/login.defs
grep pam_pwquality /etc/pam.d/common-password
pwquality=$(grep "minlen" /etc/security/pwquality.conf)
echo "  - pwquality.conf: $pwquality"
echo "  - Check for password expiration, length, complexity in above output."

echo ""
echo "[7] Sudo configuration:"
echo "  - Checking /etc/sudoers and /etc/sudoers.d/*"
sudo_attempts=$(grep "passwd_tries" /etc/sudoers)
sudo_message=$(grep "badpass_message" /etc/sudoers)
sudo_log=$(grep "logfile" /etc/sudoers)
sudo_tty=$(grep "requiretty" /etc/sudoers)
sudo_secure_path=$(grep "secure_path" /etc/sudoers)
echo "  - passwd_tries: $sudo_attempts"
echo "  - badpass_message: $sudo_message"
echo "  - logfile: $sudo_log"
echo "  - requiretty: $sudo_tty"
echo "  - secure_path: $sudo_secure_path"

echo ""
echo "[8] Monitoring script setup:"
crontab_monitor=$(crontab -l | grep monitoring.sh)
systemd_monitor=$(systemctl list-unit-files | grep monitoring-banner)
script_test=$(bash /usr/local/bin/monitoring.sh 2>&1 | grep -i error)
echo "  - monitoring.sh in crontab: $( [ -n "$crontab_monitor" ] && echo OK || echo ERROR )"
echo "  - monitoring-banner systemd service: $( [ -n "$systemd_monitor" ] && echo OK || echo ERROR )"
if [ -z "$script_test" ]; then
  echo "  - monitoring.sh runs with no errors: OK"
else
  echo "  - monitoring.sh error output: $script_test"
fi

echo ""
echo "===== End of Automated Test ====="