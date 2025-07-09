#!/bin/bash
# Assignment 2 Configuration Script

set -e

echo "~~~~~~ Starting Assignment 2 Configuration Script ~~~~~~"

# Variables
netplanFile="/etc/netplan/00-installer-config.yaml"
staticIP="192.168.16.21/24"
gateway="192.168.16.2"
dns="8.8.8.8, 1.1.1.1"

# Netplan configuration
if ! grep -q "$staticIP" "$netplanFile"; then
  echo "!!! Configuring netplan..."
  cat <<EOF > "$netplanFile"
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses: [$staticIP]
      nameservers:
        addresses: [$dns]
      routes:
        - to: 0.0.0.0/0
          via: $gateway
EOF
  chmod 600 "$netplanFile"
  netplan apply
else
  echo "!!! Netplan already configured."
fi

# /etc/hosts update
if grep -q "server1" /etc/hosts && ! grep -q "192.168.16.21.*server1" /etc/hosts; then
  sed -i '/server1/d' /etc/hosts
  echo "192.168.16.21 server1" >> /etc/hosts
elif ! grep -q "server1" /etc/hosts; then
  echo "192.168.16.21 server1" >> /etc/hosts
else
  echo "!!! /etc/hosts already correctly configured."
fi

# Software installation
for pkg in apache2 squid; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo "!!! Installing $pkg..."
    apt-get update && apt-get install -y "$pkg"
  else
    echo "!!! $pkg is already installed."
  fi
done

