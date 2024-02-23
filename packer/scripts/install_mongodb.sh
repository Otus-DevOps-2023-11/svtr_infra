#!/bin/bash
apt update
apt install mongodb -y
systemctl status mongodb
systemctl enable mongodb
