#!/bin/bash -e

read -p "Hostname [$(hostname)]: " HOSTNAME
if [[ $HOSTNAME ]] && [[ $HOSTNAME != $(hostname) ]]; then
  sudo raspi-config nonint do_hostname ${HOSTNAME:-$(hostname)}
fi

CURRENT_PRETTY_HOSTNAME=$(hostnamectl status --pretty)
read -p "Pretty hostname [${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}]: " PRETTY_HOSTNAME
sudo hostnamectl set-hostname --pretty "${PRETTY_HOSTNAME:-${CURRENT_PRETTY_HOSTNAME:-Raspberry Pi}}"

# Ensure the system audio settings match the user audio settings:
sudo ln -sfn ~/.asoundrc /etc/asound.conf

echo "Updating packages"
sudo apt update
sudo apt upgrade -y
