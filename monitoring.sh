#!/bin/bash

# monitoring.sh - Display system info on all terminals at startup and every 10 minutes

get_arch() {
  # OS architecture and kernel version
  arch=$(uname -m)
  kernel=$(uname -r)
  echo "Architecture: $arch"
  echo "Kernel version: $kernel"
}

get_cpus() {
  # Number of physical and virtual processors
  phys=$(lscpu | awk '/Socket\(s\):/ {s=$2} /Core\(s\) per socket:/ {c=$4} END {print s*c}')
  virt=$(nproc)
  echo "Physical CPUs: ${phys:-N/A}"
  echo "Virtual CPUs: $virt"
}

get_ram() {
  # RAM available and utilization
  total=$(free -m | awk '/Mem:/ {print $2}')
  used=$(free -m | awk '/Mem:/ {print $3}')
  percent=$(free | awk '/Mem:/ {printf "%.2f", $3/$2*100}')
  echo "RAM (MB): ${used}/${total} (${percent}%)"
}

get_storage() {
  # Storage available and utilization
  total=$(df -BM --total | awk '/^total/ {print $2}' | sed 's/M//')
  used=$(df -BM --total | awk '/^total/ {print $3}' | sed 's/M//')
  percent=$(df --total | awk '/^total/ {print $5}')
  echo "Storage (MB): ${used}/${total} (${percent})"
}

get_cpu_usage() {
  # CPU utilization rate
  cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
  echo "CPU usage: ${cpu}%"
}

get_last_reboot() {
  # Last reboot date/time
  last=$(who -b | awk '{print $3, $4}')
  echo "Last reboot: $last"
}

get_lvm() {
  # Is LVM active?
  lvm=$(lsblk | grep -c "lvm")
  status="no"
  [ "$lvm" -gt 0 ] && status="yes"
  echo "LVM active: $status"
}

get_active_connections() {
  # Number of active TCP connections
  conns=$(ss -tun | grep ESTAB | wc -l)
  echo "Active connections: $conns"
}

get_users() {
  # Number of users currently using the server
  users=$(who | wc -l)
  echo "Logged-in users: $users"
}

get_ip_mac() {
  # IPv4 and MAC address
  ip=$(hostname -I | awk '{print $1}')
  iface=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
  mac=$(ip link show $iface | awk '/ether/ {print $2}')
  echo "IPv4 address: $ip"
  echo "MAC address: $mac"
}

get_sudo_count() {
  # Number of sudo commands executed
  count=$(grep -c "COMMAND=" /var/log/sudo/sudo.log 2>/dev/null)
  echo "Sudo commands: $count"
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

# Run every 10 minutes via cron:
# */10 * * * * /path/to/monitoring.sh
