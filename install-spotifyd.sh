#!/bin/bash -e

echo
echo -n "Do you want to install Spotify Connect (Spotifyd)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

VERSION=v0.3.5 # pick the latest version from https://github.com/Spotifyd/spotifyd/releases

echo "Installing Spotifyd version $VERSION. Check https://github.com/Spotifyd/spotifyd/releases for newer versions."

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

## Download the latest version of Spotifyd
echo "Downloading Spotifyd $VERSION"
wget https://github.com/Spotifyd/spotifyd/releases/download/$VERSION/spotifyd-linux-armv6-slim.tar.gz
echo "Downloading completed"

## Extract the archive
echo "Extracting..."
sudo tar -C /usr/bin/ -xzf spotifyd-linux-armv6-slim.tar.gz
rm spotifyd-linux-armv6-slim.tar.gz
echo "Extraction complete"

mkdir -p ~/.config/systemd/user/

echo "[Unit]
Description=A spotify playing daemon
Documentation=https://github.com/Spotifyd/spotifyd
Wants=sound.target
After=sound.target
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/spotifyd --no-daemon --initial-volume 30 --device-type \"speaker\" --device-name \"$PRETTY_HOSTNAME\"
Restart=always 
RestartSec=12

[Install]
WantedBy=default.target" | sudo tee ~/.config/systemd/user/spotifyd.service

USERNAME=$(who | awk 'NR==1{print $1}')

systemctl --user daemon-reload
sudo loginctl enable-linger $USERNAME
systemctl --user enable spotifyd.service
