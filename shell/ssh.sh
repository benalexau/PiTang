#!/bin/bash

userdel -r -f alarm

mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

systemctl enable sshd.service
