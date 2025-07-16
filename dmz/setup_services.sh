#!/bin/bash
#
#

#!/bin/bash

# ====== CONFIGURATION ======
DOMAIN="redteam.lab"
HOSTNAME="mail.$DOMAIN"
MAILNAME="$DOMAIN"
MAIL_USER="operator"
MAIL_DIR="/home/$MAIL_USER/Maildir"
# ===========================

echo "📦 Installing Postfix..."
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix mailutils

echo "🖥️ Setting hostname and mailname..."
hostnamectl set-hostname "$HOSTNAME"
echo "$MAILNAME" > /etc/mailname

echo "⚙️ Configuring Postfix..."
postconf -e "myhostname = $HOSTNAME"
postconf -e "myorigin = /etc/mailname"
postconf -e "mydestination = $DOMAIN, localhost.localdomain, localhost"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"
postconf -e "home_mailbox = Maildir/"

echo "📁 Creating Maildir for user: $MAIL_USER"
adduser --disabled-password --gecos "" "$MAIL_USER"
sudo -u "$MAIL_USER" mkdir -p "$MAIL_DIR"
sudo -u "$MAIL_USER" mail -s "Test" "$MAIL_USER@$DOMAIN" <<< "Test message."

echo "Restarting Postfix..."
systemctl restart postfix

echo "Done. You can now send mail using:"
echo " echo 'hello' | mail -s 'test' $MAIL_USER@$DOMAIN"

