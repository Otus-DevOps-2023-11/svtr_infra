#!/bin/bash
#Script for installation ruby

#install ruby
sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential


#check "ruby"
echo " "
echo "Check versions ruby and bundler"

echo "version ruby:"
ruby -v

echo " "
echo "version bundler:"
bundler -v