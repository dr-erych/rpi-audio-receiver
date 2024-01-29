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

echo "[Unit]
Description=A spotify playing daemon
Documentation=https://github.com/Spotifyd/spotifyd
Wants=sound.target
After=sound.target
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/spotifyd --no-daemon --autoplay --initial-volume 30 --device-type \"speaker\" --device-name \"$PRETTY_HOSTNAME\"
Restart=always 
RestartSec=12

[Install]
WantedBy=default.target" | sudo tee /lib/systemd/system/spotifyd.service

sudo systemctl daemon-reload
sudo systemctl enable --now spotifyd
