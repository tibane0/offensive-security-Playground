#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi



DOMAIN="redteam.lab"
ADMIN="adminuser"
PASSWORD="P@ssw0rd1!"

wazuh_manager="10.0.0.20"

apt update && apt install -y realmd sssd sssd-tools packagekit samba-common krb5-user

echo "$PASSWORD" | realm join --user=$ADMIN $DOMAIN

realm list


# configure wazuh agent
#
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

apt-get update

apt-get install gnupg apt-transport-https
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

WAZUH_MANAGER=$wazuh_manger apt-get install wazuh-agent

# enale and start

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

#disable wazuh updates

sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
apt-get update


# dns 

DNS_SERVER="10.0.0.10"
SEARCH_DOMAIN="redteam.lab"

# Function to configure systemd-resolved
configure_systemd_resolved() {
    echo "Configuring systemd-resolved..."

    # Check if resolved.conf exists
    if [ -f /etc/systemd/resolved.conf ]; then
        # Backup original file
        cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak

        # Update resolved.conf
        sed -i "s/^#\?DNS=.*/DNS=${DNS_SERVER}/" /etc/systemd/resolved.conf
        sed -i "s/^#\?Domains=.*/Domains=${SEARCH_DOMAIN}/" /etc/systemd/resolved.conf
        sed -i "s/^#\?DNSSEC=.*/DNSSEC=no/" /etc/systemd/resolved.conf

        echo "Restarting systemd-resolved..."
        systemctl restart systemd-resolved
        echo "systemd-resolved configured successfully"
    else
        echo "/etc/systemd/resolved.conf not found, skipping systemd-resolved configuration"
    fi
}

# Function to configure Netplan
configure_netplan() {
    echo "Checking for Netplan configuration..."

    # Find the first YAML file in /etc/netplan/
    NETPLAN_FILE=$(find /etc/netplan/ -name "*.yaml" -type f | head -n 1)

    if [ -n "$NETPLAN_FILE" ]; then
        echo "Found Netplan file: $NETPLAN_FILE"

        # Backup original file
        cp "$NETPLAN_FILE" "${NETPLAN_FILE}.bak"

        # Update Netplan file with DNS settings
        if grep -q "nameservers:" "$NETPLAN_FILE"; then
            # Update existing nameservers section
            sed -i "/nameservers:/,/addresses:/ s/addresses:.*/addresses: [${DNS_SERVER}]/" "$NETPLAN_FILE"
            sed -i "/nameservers:/,/search:/ s/search:.*/search: [${SEARCH_DOMAIN}]/" "$NETPLAN_FILE" 2>/dev/null || \
            sed -i "/nameservers:/a \ \ \ \ \ \ search: [${SEARCH_DOMAIN}]" "$NETPLAN_FILE"
        else
            # Add new nameservers section
            sed -i "/version:/a \ \ nameservers:\n    addresses: [${DNS_SERVER}]\n    search: [${SEARCH_DOMAIN}]" "$NETPLAN_FILE"
        fi

        echo "Applying Netplan configuration..."
        netplan apply
        echo "Netplan configured successfully"
    else
        echo "No Netplan YAML files found in /etc/netplan/, skipping Netplan configuration"
    fi
}

# Function to configure /etc/resolv.conf directly
configure_resolv_conf() {
    echo "Configuring /etc/resolv.conf directly..."

    # Check if /etc/resolv.conf is a symlink (common with systemd-resolved)
    if [ -L /etc/resolv.conf ]; then
        echo "/etc/resolv.conf is a symlink, not modifying it directly"
        return
    fi

    # Backup original file
    cp /etc/resolv.conf /etc/resolv.conf.bak

    # Update resolv.conf
    echo "nameserver ${DNS_SERVER}" > /etc/resolv.conf
    echo "search ${SEARCH_DOMAIN}" >> /etc/resolv.conf

    echo "/etc/resolv.conf configured directly"
}

# Main execution
if systemctl is-active --quiet systemd-resolved; then
    configure_systemd_resolved
elif [ -d /etc/netplan ]; then
    configure_netplan
else
    configure_resolv_conf
fi

echo "DNS configuration complete"
