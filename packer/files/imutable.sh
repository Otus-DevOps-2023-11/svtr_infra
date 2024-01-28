#!/bin/bash
# Install requirements
wget -qO - https://www.mongodb.org/static/pgp/server-3.2.asc | sudo apt-key add - # После пайпа sudo не убрано - а то не отработает добавление ключа
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sudo apt update -y
sudo apt install git mongodb-org ruby-full ruby-bundler build-essential -y
systemctl enable mongod

# Install reddit app
mkdir /app && cd /app
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install

tee /etc/systemd/system/reddit-app.service<<EOF
[Unit]
Description=reddit monolith
Wants=network-online.target
After=network-online.target

[Service]
WorkingDirectory=/app/reddit
ExecStart=/usr/local/bin/puma
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable reddit-app
