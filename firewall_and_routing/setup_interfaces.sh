#!/bin/bash

# Backup first
cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%F_%T)

# Add bridge definitions
cat <<EOF >> /etc/network/interfaces

# ========== Custom Proxmox Lab Interfaces ==========
# vmbr0 - 192.168.2.0/24
auto vmbr0
iface vmbr0 inet static
    address 192.168.2.10
    netmask 255.255.255.0
    gateway 192.168.2.1
    bridge_ports none
    bridge_stp off
    bridge_fd 0


# vmbr1 - DMZ (172.16.1.0/24)
auto vmbr1
iface vmbr1 inet static
    address 172.16.1.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0

# vmbr2 - Internal Root (10.0.0.0/16)
auto vmbr2
iface vmbr2 inet static
    address 10.0.0.1
    netmask 255.255.0.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0

# vmbr3 - Child Domain 1 (10.0.1.0/24)
auto vmbr3
iface vmbr3 inet static
    address 10.0.1.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0

# vmbr4 - Child Domain 2 (10.0.2.0/24)
auto vmbr4
iface vmbr4 inet static
    address 10.0.2.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_stp off
    bridge_fd 0

EOF

echo "✅ Lab bridges configured. Review and restart networking:"
echo "    systemctl restart networking"
