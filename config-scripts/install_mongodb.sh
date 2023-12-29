#!/bin/bash
#Script for installation mongodb

#install mongodb
sudo apt update
sudo apt install mongodb -y

#status and start mongodb
echo " "
echo "status mongodb after install"
systemctl status mongodb

echo " "
echo "start and autostart mongodb"
sudo systemctl start mongodb
sudo systemctl enable mongodb

echo " "
echo "status mongodb after install"
systemctl status mongodb
