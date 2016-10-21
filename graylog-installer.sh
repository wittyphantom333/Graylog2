#!/bin/bash
#Provided by @mrlesmithjr
#EveryThingShouldBeVirtual.com

# Ubuntu Install Script

set -e
# Setup logging
# Logs stderr and stdout to separate files.
exec 2> >(tee "./graylog2/install_graylog2.err")
exec > >(tee "./graylog2/install_graylog2.log")

# Setup Pause function
function pause(){
   read -p "$*"
}

echo "Detecting IP Address"
IPADDY="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
echo "Detected IP Address is $IPADDY"

SERVERNAME=$IPADDY
SERVERALIAS=$IPADDY

apt-get -y install apt-transport-https openjdk-8-jre-headless uuid-runtime pwgen

apt-get -y install mongodb-server

wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
apt-get update && sudo apt-get -y install elasticsearch


sed -i -e 's|#cluster.name: elasticsearch|cluster.name: graylog|' /etc/elasticsearch/elasticsearch.yml


systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service

wget https://packages.graylog2.org/repo/packages/graylog-2.1-repository_latest.deb
dpkg -i graylog-2.1-repository_latest.deb
apt-get update && sudo apt-get install graylog-server



#Install graylog2-server
echo "Installing graylog2-server"
echo -n "Enter a password to use for the admin account to login to the Graylog2 webUI: "
read adminpass
echo "You entered $adminpass (MAKE SURE TO NOT FORGET THIS PASSWORD!)"
pause 'Press [Enter] key to continue...'

pass_secret=$(pwgen -s 96)
sed -i -e 's|password_secret =|password_secret = '$pass_secret'|' /etc/graylog/server/server.conf
#root_pass_sha2=$(echo -n password123 | shasum -a 256)
admin_pass_hash=$(echo -n $adminpass|sha256sum|awk '{print $1}')
sed -i -e "s|root_password_sha2 =|root_password_sha2 = $admin_pass_hash|" /etc/graylog/server/server.conf
#sed -i -e 's|elasticsearch_shards = 4|elasticsearch_shards = 1|' /etc/graylog/server/server.conf
#sed -i -e 's|mongodb_useauth = true|mongodb_useauth = false|' /etc/graylog/server/server.conf
#sed -i -e 's|#elasticsearch_discovery_zen_ping_multicast_enabled = false|elasticsearch_discovery_zen_ping_multicast_enabled = false|' /etc/graylog/server/server.conf
#sed -i -e 's|#elasticsearch_discovery_zen_ping_unicast_hosts = 192.168.1.203:9300|elasticsearch_discovery_zen_ping_unicast_hosts = 127.0.0.1:9300|' /etc/graylog/server/server.conf

# Setting new retention policy setting or Graylog2 Server will not start
#sed -i 's|retention_strategy = delete|retention_strategy = close|' /etc/graylog/server/server.conf

# This setting is required as of v0.20.2 in /etc/graylog2.conf
sed -i -e 's|#rest_transport_uri = http://192.168.1.1:12900/|rest_transport_uri = http://127.0.0.1:12900/|' /etc/graylog/server/server.conf


sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl start graylog-server.service