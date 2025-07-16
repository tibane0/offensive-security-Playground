#!/bin/bash

# Variables
DOMAIN="infosec.lab"
DNS_IP="172.16.1.10"
REVERSE_ZONE="1.16.172.in-addr.arpa"

echo "🔧 Installing BIND9..."
apt update && apt install -y bind9 bind9utils bind9-doc

echo "🛠️ Configuring /etc/bind/named.conf.options..."
cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";

    recursion no;
    allow-query { 127.0.0.1; 172.16.1.0/24; 10.0.0.0/24; 192.168.2.0/24 }; # Ext, DMZ and internal 

    listen-on { 127.0.0.1; $DNS_IP; };
    allow-transfer { none; };

    dnssec-validation no;
    forwarders {};
};
EOF

echo "🛠️ Creating zone file for $DOMAIN..."
cat > /etc/bind/db.$DOMAIN <<EOF
\$TTL    604800
@       IN      SOA     ns.$DOMAIN. admin.$DOMAIN. (
                            3         ; Serial
                       604800         ; Refresh
                        86400         ; Retry
                      2419200         ; Expire
                       604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.$DOMAIN.
ns      IN      A       $DNS_IP

# DMZ records
www     IN      A       172.16.1.10
mail    IN      A       172.16.1.10
dns     IN      A       172.16.1.10

EOF

echo "🛠️ Creating reverse zone file..."
cat > /etc/bind/db.172.rev <<EOF
\$TTL    604800
@       IN      SOA     ns.$DOMAIN. admin.$DOMAIN. (
                            3         ; Serial
                       604800         ; Refresh
                        86400         ; Retry
                      2419200         ; Expire
                       604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.$DOMAIN.

10      IN      PTR     www.$DOMAIN.
11      IN      PTR     mail.$DOMAIN.
53      IN      PTR     dns.$DOMAIN.
EOF

echo "🧩 Adding zones to /etc/bind/named.conf.local..."
cat >> /etc/bind/named.conf.local <<EOF

zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
};

zone "$REVERSE_ZONE" {
    type master;
    file "/etc/bind/db.172.rev";
};
EOF

echo "🔄 Restarting BIND9..."
systemctl restart bind9

echo "✅ DNS server $DOMAIN active at $DNS_IP in the DMZ"
