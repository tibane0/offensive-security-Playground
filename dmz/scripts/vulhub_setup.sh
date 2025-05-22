#!/bin/bash
cd /opt/vulhub

# Stop any previously running docker-compose services
find . -name docker-compose.yml -execdir docker-compose down \;

# Find all vuln projects with docker-compose.yml
mapfile -t VULNS < <(find . -name docker-compose.yml | sed 's|/docker-compose.yml||')

# Select one at random
SELECTED="${VULNS[$RANDOM % ${#VULNS[@]}]}"

echo "[*] Launching $SELECTED..."
cd "$SELECTED" && docker-compose up -d
