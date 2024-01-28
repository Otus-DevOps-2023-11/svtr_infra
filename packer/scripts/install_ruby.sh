#!/bin/bash
apt-get update
pkill -9 apt
apt-get install -y ruby-full ruby-bundler build-essential