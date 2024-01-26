#!/bin/bash -e

sudo apt update
sudo apt upgrade -y

wget -O madfu-firmware.zip https://github.com/osxmidi/madfu-firmware-mirror/zipball/master
unzip madfu-firmware.zip -d ./madfu-firmware
cd madfu-firmware/*
./configure
make
sudo make install
cd -
rm madfu-firmware.zip
rm -rf madfu-firmware/

echo 'blacklist snd_bcm2835' | sudo tee /etc/modprobe.d/blacklist-onboard-audio.conf
sudo sed -e '/options snd-usb-audio index=-2/ s/^#*/#/' -i /lib/modprobe.d/aliases.conf

echo "Please reboot now."
