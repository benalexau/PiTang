#!/bin/bash

pacman -S --noconfirm tang

ls -l /tmp
ls -l /tmp/file-copy

mkdir -p /var/db/tang

mv /tmp/file-copy/pitang-setup /usr/bin
mv /tmp/file-copy/pitang-lock /usr/bin
mv /tmp/file-copy/pitang-unlock /usr/bin

mv /tmp/file-copy/pitang-ip-bound-hmac-setup /usr/bin
mv /tmp/file-copy/pitang-ip-bound-hmac-remove /usr/bin
mv /tmp/file-copy/pitang-ip-bound-hmac-unlock /usr/bin

chmod 770 /usr/bin/pitang-*

mv /tmp/file-copy/pitang-ip-bound-hmac-unlock.service /etc/systemd/system
mv /tmp/file-copy/pitang-ip-bound-hmac-unlock.timer /etc/systemd/system
