#!/bin/bash

pacman -S --noconfirm tang

ls -l /tmp
ls -l /tmp/file-copy


mv /tmp/file-copy/pitang-* /usr/bin
chmod 770 /usr/bin/pitang-*
