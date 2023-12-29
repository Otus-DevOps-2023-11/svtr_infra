#!/bin/bash
#Script for installation app

#download
sudo cd /home/yc-user
sudo apt install git -y
sudo git clone -b monolith https://github.com/express42/reddit.git

#install
cd reddit
bundle install

#start app
puma -d
ps aux | grep puma