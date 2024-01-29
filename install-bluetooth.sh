#!/bin/bash -e

read -p "Do you want to install Bluetooth Audio (ALSA)? [y/N] " REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then return; fi

# Bluetooth Audio ALSA Backend (bluez-alsa-utils)

if [[ -z "$TMP_DIR" ]]; then
    TMP_DIR=$(mktemp -d)
fi

cd $TMP_DIR

wget -O bluez-alsa-master.zip https://github.com/arkq/bluez-alsa/archive/refs/heads/master.zip
unzip bluez-alsa-master.zip
cd bluez-alsa-master

sudo apt install automake build-essential libtool pkg-config python3-docutils libasound2-dev libbluetooth-dev libdbus-1-dev libglib2.0-dev libsbc-dev

autoreconf --install --force

mkdir build
cd build

../configure --enable-ofono --enable-debug

make
sudo make install


# TODO automate discovery of devices and create autopairing config
# https://gist.github.com/fagnercarvalho/2755eaa492a8aa27081e0e0fe7780d14
