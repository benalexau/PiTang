#!/bin/bash
pacman-key --init
pacman-key --populate archlinuxarm

pacman -Syu --noconfirm

# Small utilities to help with administration over SSH
pacman -S --noconfirm mg rxvt-unicode-terminfo bash-completion

# Enable compiling from AUR
pacman -S --noconfirm base-devel
cd /tmp

# Install AUR:watchdog
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/watchdog.tar.gz
tar -xvf watchdog.tar.gz
cd watchdog
su -c "makepkg -si --noconfirm" alarm
exit
pacman -U watchdog-*.tar.zst

# Disable compiling from AUR
cd /tmp
pacman -Rs --noconfirm base-devel

# Recover space
rm /var/cache/pacman/pkg/*.xz
