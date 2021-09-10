#!/usr/bin/env bash
set -e

echo "Installing dependencies..."
if [ -x "$(command -v apt-get)" ]; then
  sudo su -s /bin/bash -c 'sleep 30 && apt-get update && apt-get install unzip' root
fi

echo "Fetching nomad..."
NOMAD=1.0.1
cd /tmp
wget https://releases.hashicorp.com/nomad/${NOMAD}/nomad_${NOMAD}_linux_amd64.zip -O nomad.zip --quiet

echo "Installing nomad..."
unzip nomad.zip >/dev/null
chmod +x nomad
sudo mv nomad /usr/local/bin/nomad
sudo mkdir -p /opt/nomad/data

echo "Read from the file we created"
if [ -f /tmp/nomad-server-count ]; then
  SERVER_COUNT=$(cat /tmp/nomad-server-count | tr -d '\n')
else
  CLIENT_COUNT=$(cat /tmp/nomad-client-count | tr -d '\n')
fi

NOMAD_JOIN=$(cat /tmp/nomad-server-addr | tr -d '\n')

echo 'Write the flags to a temporary file'
SERVER_FILE=/tmp/nomad-server-count
if [ -f "$SERVER_FILE" ]; then
    echo "$SERVER_FILE exists."
    cat >/tmp/nomad.conf << EOF
datacenter = "dc1"
data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0" # the default

advertise {
  # Defaults to the first private IP address.
  # http = "1.2.3.4"
  # rpc  = "1.2.3.4"
  # serf = "1.2.3.4:5648" # non-default ports may be specified
}

server {
   enabled          = true
   bootstrap_expect = 1
}

client {
  enabled       = false
}

plugin "raw_exec" {
  config {
      enabled = true
  }
}

consul {
   address = "127.0.0.1:8500"
}
EOF
else 
    echo "$SERVER_FILE does not exist."
    cat >/tmp/nomad.conf << EOF
datacenter = "dc1"
data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0" # the default

advertise {
  # Defaults to the first private IP address.
  # http = "1.2.3.4"
  # rpc  = "1.2.3.4"
  # serf = "1.2.3.4:5648" # non-default ports may be specified
}

server {
   enabled          = false
}

client {
  enabled       = true
}

plugin "raw_exec" {
  config {
      enabled = true
  }
}

consul {
   address = "127.0.0.1:8500"
}
EOF
fi

echo "Installing Systemd service..."
sudo mkdir -p /etc/sysconfig
sudo mkdir -p /etc/systemd/system/nomad.d
sudo chown root:root /tmp/nomad.service
sudo mv /tmp/nomad.service /etc/systemd/system/nomad.service
sudo mv /tmp/nomad*json /etc/systemd/system/nomad.d/ || echo
sudo chmod 0644 /etc/systemd/system/nomad.service
sudo mv /tmp/nomad.conf /etc/sysconfig/nomad.conf
sudo chown root:root /etc/sysconfig/nomad.conf
sudo chmod 0644 /etc/sysconfig/nomad.conf
