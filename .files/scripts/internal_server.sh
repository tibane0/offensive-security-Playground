#!/bin/bash
#

# run vulhub docker images
apt update
apt install -y docker.io docker-compose wget curl php \
       cron ftp openssh-server netcat-traditional \
       python3 apache2 mysqli vsftpd

systemctl start docker
systemctl enable docker

systemctl start apache
systemctl enable apache


cd /opt/vulhub

# Stop any previously running docker-compose services
find . -name docker-compose.yml -execdir docker-compose down \;

# Find all vuln projects with docker-compose.yml
mapfile -t VULNS < <(find . -name docker-compose.yml | sed 's|/docker-compose.yml||')

# Select one at random
SELECTED="${VULNS[$RANDOM % ${#VULNS[@]}]}"

echo "[*] Launching $SELECTED..."
cd "$SELECTED" && docker-compose up -d

#set up ftp 
#

