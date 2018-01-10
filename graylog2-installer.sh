#!/bin/bash
#Provided by wittyphantom333
#VirtualEvolutions.com

# Ubuntu Install Script

# Setup logging
set -e
exec 2> >(tee "./graylog2/install_graylog2.err")
exec > >(tee "./graylog2/install_graylog2.log")

# Setup Pause function
function pause(){
   read -p "$*"
}

# Detect IP Address
echo "Detecting IP Address"
IPADDY="$(ifconfig | grep -A 1 'ens160' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
echo "Detected IP Address is $IPADDY"

SERVERNAME=$IPADDY
SERVERALIAS=$IPADDY

# Install Pre-reqs
apt-get -y install apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen

# Install MongoDB
apt-get -y install mongodb-server

# Install Elacticsearch
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
apt-get update && sudo apt-get -y install elasticsearch
sed -i -e 's|# cluster.name: my-application|cluster.name: graylog|' /etc/elasticsearch/elasticsearch.yml
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service

# Install Graylog
wget https://packages.graylog2.org/repo/packages/graylog-2.4-repository_latest.deb
dpkg -i graylog-2.4-repository_latest.deb
apt-get update && sudo apt-get install graylog-server



# Configure Graylog Server
echo "Installing graylog2-server"
echo -n "Enter a password to use for the admin account to login to the Graylog2 webUI: "
read adminpass
echo "You entered $adminpass (MAKE SURE TO NOT FORGET THIS PASSWORD!)"
pause 'Press [Enter] key to continue...'

pass_secret=$(pwgen -s 96)
sed -i -e 's|password_secret =|password_secret = '$pass_secret'|' /etc/graylog/server/server.conf

admin_pass_hash=$(echo -n $adminpass|sha256sum|awk '{print $1}')
sed -i -e "s|root_password_sha2 =|root_password_sha2 = $admin_pass_hash|" /etc/graylog/server/server.conf

sed -i -e 's|rest_listen_uri = http://127.0.0.1:9000/api/|rest_listen_uri = http://'$IPADDY':12900/|' /etc/graylog/server/server.conf
sed -i -e 's|#web_listen_uri = http://127.0.0.1:9000/|web_listen_uri = http://'$IPADDY':9000/|' /etc/graylog/server/server.conf


sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl start graylog-server.service

# All Done
echo "Installation has completed!!"
echo "Browse to IP address of this Graylog2 Server Used for Installation"
echo "IP Address detected from system is $IPADDY"
echo "Browse to http://$IPADDY:9000"
echo "Login with username: admin"
echo "Login with password: $adminpass"