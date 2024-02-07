#!/bin/bash
# This is the first script that you should run if you a running a container
apt update
apt install openssh-server vim net-tools -y
systemctl enable ssh
systemctl start ssh
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl restart ssh
