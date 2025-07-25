#!/bin/bash
#Assignment 2 Configuration Script by Kaden McTavish. Ensures correct network settings, users, SSH keys and services are installed.

set -e #Causes script to end if any command fails.

echo "~~~~~~ Starting Assignment 2 Configuration Script ~~~~~~"

#Variables - Specifies desired IP settings and the list of users to create.
netplanFile="/etc/netplan/00-installer-config.yaml"
staticIP="192.168.16.21/24"
gateway="192.168.16.2"
dns="8.8.8.8, 1.1.1.1"
requiredUsers=(dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda)
dennisKey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

#Netplan configuration - Configures a static IP address, disables DHCP, sets the DNS and sets a default route.
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

#/etc/hosts Update - Ensures the hostanme server1 points to the correct IP and cleans up old entires if necessary.
if grep -q "server1" /etc/hosts && ! grep -q "192.168.16.21.*server1" /etc/hosts; then
  sed -i '/server1/d' /etc/hosts
  echo "192.168.16.21 server1" >> /etc/hosts
elif ! grep -q "server1" /etc/hosts; then
  echo "192.168.16.21 server1" >> /etc/hosts
else
  echo "!!! /etc/hosts already correctly configured."
fi

#Apache and Squid Installation - Installs both packages if they are not installed.
for pkg in apache2 squid; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo "!!! Installing $pkg..."
    apt-get update && apt-get install -y "$pkg"
  else
    echo "!!! $pkg is already installed."
  fi
done

#User and SSH configuration - Creates users if they do not exist, sets the .ssh folder and the perms, generates both RSA and ED25519 SSH key pairs if they do not exist. Concatenates both public keys into the authorized keys. Adds a custom key for dennis and adds him to the sudo group.
for user in "${requiredUsers[@]}"; do
  if ! id "$user" &>/dev/null; then
    echo "!!! Creating user: $user"
    useradd -m -s /bin/bash "$user"
  else
    echo "!!! User $user already exists."
  fi

  homeDir="/home/$user"
  sshDir="$homeDir/.ssh"
  authKeys="$sshDir/authorized_keys"

  #Create .ssh directory and fix ownership before keygen
  mkdir -p "$sshDir"
  chown "$user:$user" "$sshDir"
  chmod 700 "$sshDir"

  #Generate keys as the user
  if [ ! -f "$sshDir/id_rsa.pub" ]; then
    sudo -u "$user" ssh-keygen -t rsa -b 2048 -f "$sshDir/id_rsa" -N "" || echo "!ERROR! Failed RSA for $user"
  fi

  if [ ! -f "$sshDir/id_ed25519.pub" ]; then
    sudo -u "$user" ssh-keygen -t ed25519 -f "$sshDir/id_ed25519" -N "" || echo "!ERROR! Failed ED25519 for $user"
  fi

  #Combine into authorized_keys
  cat "$sshDir/id_rsa.pub" "$sshDir/id_ed25519.pub" > "$authKeys"

  #For Dennis, adds a key and sudo group
  if [ "$user" == "dennis" ]; then
    if ! grep -q "$dennisKey" "$authKeys"; then
      echo "$dennisKey" >> "$authKeys"
    fi
    usermod -aG sudo dennis
    echo "!!! Sudo access granted to dennis."
  fi

  chmod 600 "$authKeys"
  chown -R "$user:$user" "$sshDir"
done

echo "~~~~~~ Configuration Complete ~~~~~~"
