#!/bin/bash

# -=-=-=-=- CLRS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
DEF_COLOR='\033[0;39m'
BLACK='\033[0;30m'
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
MAGENTA='\033[0;95m'
CYAN='\033[0;96m'
GRAY='\033[0;90m'
WHITE='\033[0;97m'

printf ${BLUE}"\n-------------------------------------------------------------\n"${DEF_COLOR};
printf ${YELLOW}"\n\t\tTEST & AUTO-FIX CREATED BY: "${DEF_COLOR};
printf ${CYAN}"COPILOT & GEMARTIN\t\n"${DEF_COLOR};
printf ${BLUE}"\n-------------------------------------------------------------\n"${DEF_COLOR};

USER=$(whoami)
if [ $USER != "root" ];then
  printf "${RED}You must be in the root user to run the test.${DEF_COLOR}\n";
  exit 1;
fi

# -=-=-=-=- Graphical environment -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
printf "${MAGENTA}Graphical environment${DEF_COLOR}\n";
if [ -f /usr/bin/dbus-run-session ]; then
  printf "${GREEN}[OK] ${DEF_COLOR}\n";
else
  printf "${RED}[KO] ${DEF_COLOR}\n";
  printf "${YELLOW}Attempting to fix...${DEF_COLOR}\n";
  apt-get update -qq
  apt-get install -y dbus-x11
fi

# -=-=-=-=- Disk partitions -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
printf "${MAGENTA}Disk partitions${DEF_COLOR}\n";
if [ $(lsblk | grep lvm | wc -l) -le 1 ]; then
  printf "${RED}[KO] LVM missing${DEF_COLOR}\n";
  # LVM auto-fix is risky, so we just warn.
  printf "${YELLOW}Manual intervention required to create LVM partitions${DEF_COLOR}\n";
else
  printf "${GREEN}[OK] LVM exists${DEF_COLOR}\n";
fi
if ! lsblk | grep -q home; then
  printf "${RED}[KO] 'home' partition missing${DEF_COLOR}\n";
  printf "${YELLOW}Manual intervention required to create 'home' partition${DEF_COLOR}\n";
else
  printf "${GREEN}[OK] 'home' partition exists${DEF_COLOR}\n";
fi
if ! lsblk | grep -q swap; then
  printf "${RED}[KO] 'swap' partition missing${DEF_COLOR}\n";
  printf "${YELLOW}Attempting to create swap partition...${DEF_COLOR}\n";
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
else
  printf "${GREEN}[OK] 'swap' partition exists${DEF_COLOR}\n";
fi
if ! lsblk | grep -q root; then
  printf "${RED}[KO] 'root' partition missing${DEF_COLOR}\n";
else
  printf "${GREEN}[OK] 'root' partition exists${DEF_COLOR}\n";
fi

# -=-=-=-=- SSH checks -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
printf "${MAGENTA}SSH${DEF_COLOR}\n";
if ! service ssh status 2>/dev/null | grep -q "running"; then
  printf "${RED}[KO] SSH not running${DEF_COLOR}\n";
  printf "${YELLOW}Attempting to start SSH...${DEF_COLOR}\n";
  apt-get install -y openssh-server
  systemctl enable ssh
  systemctl start ssh
else
  printf "${GREEN}[OK] SSH running${DEF_COLOR}\n";
fi

if [ $(which lsof | wc -l) -eq 0 ]; then
  apt-get update -qq
  apt-get install -y lsof
fi

if [ $(lsof -i -P -n | grep sshd | grep LISTEN | grep 4242 | wc -l) -le 1 ]; then
  printf "${RED}[KO] SSH not listening on 4242${DEF_COLOR}\n";
  printf "${YELLOW}Attempting to configure SSH for port 4242...${DEF_COLOR}\n";
  if ! grep -q "^Port 4242" /etc/ssh/sshd_config; then
    echo "Port 4242" >> /etc/ssh/sshd_config
    systemctl restart ssh
  fi
else
  printf "${GREEN}[OK] SSH listening on 4242${DEF_COLOR}\n";
fi

# -=-=-=-=- UFW checks -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
printf "${MAGENTA}UFW${DEF_COLOR}\n";
if ! ufw status | grep -q active; then
  printf "${RED}[KO] UFW not active${DEF_COLOR}\n";
  printf "${YELLOW}Enabling UFW...${DEF_COLOR}\n";
  ufw enable
else
  printf "${GREEN}[OK] UFW active${DEF_COLOR}\n";
fi

if [ $(ufw status | grep 4242 | wc -l) -le 1 ]; then
  printf "${RED}[KO] UFW not allowing port 4242${DEF_COLOR}\n";
  printf "${YELLOW}Allowing port 4242 on UFW...${DEF_COLOR}\n";
  ufw allow 4242/tcp
else
  printf "${GREEN}[OK] UFW allows port 4242${DEF_COLOR}\n";
fi

# -=-=-=-=- Hostname checks -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
printf "${MAGENTA}Hostname${DEF_COLOR}\n";
USER_WH=$(who | head -1 | cut -d ' ' -f1)
CONCAT="42"
EXPECTED_HOSTNAME="${USER_WH}${CONCAT}"
ACTUAL_HOSTNAME=$(hostname)
if [ "$EXPECTED_HOSTNAME" != "$ACTUAL_HOSTNAME" ]; then
  printf "${RED}[KO] Hostname incorrect${DEF_COLOR}\n";
  printf "${YELLOW}Setting hostname to ${EXPECTED_HOSTNAME}...${DEF_COLOR}\n";
  hostnamectl set-hostname "$EXPECTED_HOSTNAME"
else
  printf "${GREEN}[OK] Hostname correct${DEF_COLOR}\n";
fi

# -=-=-=-=- Password policy -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
printf "${MAGENTA}Password policy${DEF_COLOR}\n";
fix_pam=false
PAM_FILE="/etc/pam.d/common-password"
LOGIN_FILE="/etc/login.defs"

# minlen
if ! grep -q "minlen=10" $PAM_FILE; then
  printf "${RED}1.[KO] minlen${DEF_COLOR}\n";
  sed -i '/pam_pwquality.so/ s/$/ minlen=10/' $PAM_FILE
  fix_pam=true
else
  printf "${GREEN}1.[OK] minlen${DEF_COLOR}\n";
fi
# ucredit
if ! grep -q "ucredit=-1" $PAM_FILE; then
  printf "${RED}2.[KO] uppercase${DEF_COLOR}\n";
  sed -i '/pam_pwquality.so/ s/$/ ucredit=-1/' $PAM_FILE
  fix_pam=true
else
  printf "${GREEN}2.[OK] uppercase${DEF_COLOR}\n";
fi
# lcredit
if ! grep -q "lcredit=-1" $PAM_FILE; then
  printf "${RED}3.[KO] lowercase${DEF_COLOR}\n";
  sed -i '/pam_pwquality.so/ s/$/ lcredit=-1/' $PAM_FILE
  fix_pam=true
else
  printf "${GREEN}3.[OK] lowercase${DEF_COLOR}\n";
fi
# dcredit
if ! grep -q "dcredit=-1" $PAM_FILE; then
  printf "${RED}4.[KO] digit${DEF_COLOR}\n";
  sed -i '/pam_pwquality.so/ s/$/ dcredit=-1/' $PAM_FILE
  fix_pam=true
else
  printf "${GREEN}4.[OK] digit${DEF_COLOR}\n";
fi
# maxrepeat
if ! grep -q "maxrepeat=3" $PAM_FILE; then
  printf "${RED}5.[KO] consecutive char${DEF_COLOR}\n";
  sed -i '/pam_pwquality.so/ s/$/ maxrepeat=3/' $PAM_FILE
  fix_pam=true
else
  printf "${GREEN}5.[OK] consecutive char${DEF_COLOR}\n";
fi
# difok
if ! grep -q "difok=7" $PAM_FILE; then
  printf "${RED}6.[KO] difok${DEF_COLOR}\n";
  sed -i '/pam_pwquality.so/ s/$/ difok=7/' $PAM_FILE
  fix_pam=true
else
  printf "${GREEN}6.[OK] difok${DEF_COLOR}\n";
fi
# enforce_for_root
if ! grep -q "enforce_for_root" $PAM_FILE; then
  printf "${RED}7.[KO] enforce for root${DEF_COLOR}\n";
  sed -i '/pam_pwquality.so/ s/$/ enforce_for_root/' $PAM_FILE
  fix_pam=true
else
  printf "${GREEN}7.[OK] enforce for root${DEF_COLOR}\n";
fi
# reject_username
if ! grep -q "reject_username" $PAM_FILE; then
  printf "${RED}8.[KO] reject username${DEF_COLOR}\n";
  sed -i '/pam_pwquality.so/ s/$/ reject_username/' $PAM_FILE
  fix_pam=true
else
  printf "${GREEN}8.[OK] reject username${DEF_COLOR}\n";
fi

# login.defs
if ! grep -q "PASS_MAX_DAYS.*30" $LOGIN_FILE; then
  printf "${RED}9.[KO] passwd expire days${DEF_COLOR}\n";
  sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   30/' $LOGIN_FILE
else
  printf "${GREEN}9.[OK] passwd expire days${DEF_COLOR}\n";
fi
if ! grep -q "PASS_MIN_DAYS.*2" $LOGIN_FILE; then
  printf "${RED}10.[KO] days allowed before modification${DEF_COLOR}\n";
  sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   2/' $LOGIN_FILE
else
  printf "${GREEN}10.[OK] days allowed before modification${DEF_COLOR}\n";
fi
if ! grep -q "PASS_WARN_AGE.*7" $LOGIN_FILE; then
  printf "${RED}11.[KO] warning message${DEF_COLOR}\n";
  sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' $LOGIN_FILE
else
  printf "${GREEN}11.[OK] warning message${DEF_COLOR}\n";
fi

if [ "$fix_pam" = true ]; then
  printf "${YELLOW}Password policy settings updated. Please test again!${DEF_COLOR}\n";
fi

if [ -d "/var/log/sudo/" ];then
  printf "${GREEN}12.[OK] folder /var/log/sudo exists${DEF_COLOR}\n";
else
  printf "${RED}12.[KO] folder /var/log/sudo missing${DEF_COLOR}\n";
  printf "${YELLOW}Creating /var/log/sudo folder...${DEF_COLOR}\n";
  mkdir -p /var/log/sudo
fi

# -=-=-=-=- Crontab checks -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
printf "${MAGENTA}Crontab${DEF_COLOR}\n";
CRON_OK=$(crontab -l 2>/dev/null | grep monitoring.sh | awk '$1 == "*/10" {print $1}')
if [ "$CRON_OK" != "*/10" ]; then
  printf "${RED}[KO] monitoring.sh not scheduled every 10 min${DEF_COLOR}\n";
  printf "${YELLOW}Adding monitoring.sh to crontab...${DEF_COLOR}\n";
  (crontab -l 2>/dev/null; echo "*/10 * * * * /root/monitoring.sh") | crontab -
else
  printf "${GREEN}[OK] monitoring.sh scheduled${DEF_COLOR}\n";
fi

echo