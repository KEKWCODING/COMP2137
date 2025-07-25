#!/bin/bash
# Quick and dirty install of the puppet8 agent on Ubuntu 22.04 systems
# Hardcoded puppet master IP is 172.16.1.1 (default for most labs)

echo "Adding puppet server to /etc/hosts file if necessary"
grep -q ' puppet$' /etc/hosts || sudo sed -i -e '$a172.16.1.1 puppet' /etc/hosts

echo "Setting up for puppet8 and installing agent on $(hostname)"
wget -q https://apt.puppet.com/puppet8-release-jammy.deb
dpkg -i puppet8-release-jammy.deb
apt-get -qq update

echo "Installing puppet agent (snapd.seeded.service can take a long time, be patient)"
NEEDRESTART_MODE=a apt-get -y install puppet-agent >/dev/null

echo "Adding puppet tools to PATH for future shell sessions"
sed -i '$aPATH=$PATH:/opt/puppetlabs/bin' /home/remoteadmin/.bashrc

echo "Requesting a certificate from puppet master"
sudo /opt/puppetlabs/bin/puppet ssl bootstrap &
