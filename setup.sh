#!/bin/bash
# Born2beRoot automated setup script for Debian
# Run as root!

# ---- CONFIG ----
LOGIN="lhuang"     # Set your login
HOSTNAME="${LOGIN}42"     # Hostname pattern
SSH_PORT=4242
USER_GROUP="user42"
# ----------------

echo "--= Born2beRoot Setup for Debian =--"

# 1. Set hostname
hostnamectl set-hostname "$HOSTNAME"

# 2. Set up user and groups
if ! id "$LOGIN" &>/dev/null; then
    groupadd -f $USER_GROUP
    useradd -m -G $USER_GROUP,sudo $LOGIN
    echo "Set password for $LOGIN:"
    passwd $LOGIN
fi

# 3. SSH config: port and root login
sshd_cfg="/etc/ssh/sshd_config"
cp $sshd_cfg $sshd_cfg.bak.$(date +%s)
sed -i "s/^#*Port .*/Port $SSH_PORT/" $sshd_cfg
sed -i "s/^#*PermitRootLogin .*/PermitRootLogin no/" $sshd_cfg
if ! grep -q "^Port $SSH_PORT" $sshd_cfg; then
    echo "Port $SSH_PORT" >> $sshd_cfg
fi
if ! grep -q "^PermitRootLogin no" $sshd_cfg; then
    echo "PermitRootLogin no" >> $sshd_cfg
fi
systemctl restart ssh

# 4. AppArmor
apt-get update
apt-get install -y apparmor libpam-pwquality ufw sudo
systemctl enable --now apparmor

# 5. Firewall (UFW)
ufw allow ${SSH_PORT}/tcp
ufw default deny incoming
ufw --force enable

# 6. Password Policy
LOGINDEFS="/etc/login.defs"
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   30/' $LOGINDEFS
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   2/' $LOGINDEFS
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' $LOGINDEFS

PAMFILE="/etc/pam.d/common-password"
if ! grep -q pam_pwquality $PAMFILE; then
    echo "password requisite pam_pwquality.so retry=3 minlen=10 ucredit=-1 lcredit=-1 dcredit=-1 maxrepeat=3 reject_username difok=7" >> $PAMFILE
fi

# 7. Sudo settings
SUDOERS="/etc/sudoers"
for line in \
    "Defaults        passwd_tries=3" \
    "Defaults        badpass_message=\"Wrong password, try again.\"" \
    "Defaults        logfile=\"/var/log/sudo/sudo.log\"" \
    "Defaults        log_input,log_output" \
    "Defaults        requiretty" \
    "Defaults secure_path=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin\""
do
    grep -qF "$line" $SUDOERS || echo "$line" >> $SUDOERS
done

# 8. Sudo logging folder
mkdir -p /var/log/sudo
touch /var/log/sudo/sudo.log
chmod 600 /var/log/sudo/sudo.log

# 9. monitoring.sh setup
cat > /usr/local/bin/monitoring.sh <<'EOF'
#!/bin/bash
get_arch() { echo "Architecture: $(uname -m)"; echo "Kernel version: $(uname -r)"; }
get_cpus() {
  phys=$(lscpu | awk '/Socket\(s\):/ {s=$2} /Core\(s\) per socket:/ {c=$4} END {print s*c}');
  virt=$(nproc);
  echo "Physical CPUs: ${phys:-N/A}"; echo "Virtual CPUs: $virt";
}
get_ram() {
  total=$(free -m | awk '/Mem:/ {print $2}');
  used=$(free -m | awk '/Mem:/ {print $3}');
  percent=$(free | awk '/Mem:/ {printf "%.2f", $3/$2*100}');
  echo "RAM (MB): ${used}/${total} (${percent}%)";
}
get_storage() {
  total=$(df -BM --total | awk '/^total/ {print $2}' | sed 's/M//');
  used=$(df -BM --total | awk '/^total/ {print $3}' | sed 's/M//');
  percent=$(df --total | awk '/^total/ {print $5}');
  echo "Storage (MB): ${used}/${total} (${percent})";
}
get_cpu_usage() {
  cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}');
  echo "CPU usage: ${cpu}%";
}
get_last_reboot() {
  last=$(who -b | awk '{print $3, $4}');
  echo "Last reboot: $last";
}
get_lvm() {
  lvm=$(lsblk | grep -c "lvm");
  status="no"; [ "$lvm" -gt 0 ] && status="yes";
  echo "LVM active: $status";
}
get_active_connections() {
  conns=$(ss -tun | grep ESTAB | wc -l);
  echo "Active connections: $conns";
}
get_users() {
  users=$(who | wc -l);
  echo "Logged-in users: $users";
}
get_ip_mac() {
  ip=$(hostname -I | awk '{print $1}');
  iface=$(ip route get 8.8.8.8 | awk '{print $5; exit}');
  mac=$(ip link show $iface | awk '/ether/ {print $2}');
  echo "IPv4 address: $ip";
  echo "MAC address: $mac";
}
get_sudo_count() {
  count=$(grep -c "COMMAND=" /var/log/sudo/sudo.log 2>/dev/null);
  echo "Sudo commands: $count";
}
main() {
  {
    echo "------ System Monitoring ------"
    get_arch
    get_cpus
    get_ram
    get_storage
    get_cpu_usage
    get_last_reboot
    get_lvm
    get_active_connections
    get_users
    get_ip_mac
    get_sudo_count
    echo "------------------------------"
  } | wall
}
main
EOF
chmod +x /usr/local/bin/monitoring.sh

# 10. Systemd service for monitoring
cat > /etc/systemd/system/monitoring-banner.service <<EOF
[Unit]
Description=System Monitoring Banner

[Service]
Type=oneshot
ExecStart=/usr/local/bin/monitoring.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable monitoring-banner.service

# 11. Cron job for monitoring (every 10 min)
(crontab -l 2>/dev/null; echo "*/10 * * * * /usr/local/bin/monitoring.sh") | crontab -

echo "== Basic Debian setup done. =="
echo "Manual steps remaining:"
echo "  - Partitioning/encrypting disks with LVM (must be done during install!)"
echo "  - Reset all user/root passwords AFTER policy is in place"
echo "  - Test SSH login on port $SSH_PORT"
echo "  - Optionally, set up /etc/motd or /etc/profile for monitoring info at login"
echo "  - Reboot to apply all kernel/AppArmor changes"
