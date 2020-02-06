#!/bin/bash

cd /tmp
wget https://github.com/mikefarah/yq/releases/download/3.0.1/yq_linux_amd64 
sudo cp ./yq_linux_amd64 /usr/local/bin/yq
sudo chmod 755 /usr/local/bin/yq

yq --version