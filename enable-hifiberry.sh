#!/bin/bash -e

echo
echo -n "Do you want to enable HiFiBerry device tree overlay and ALSA configuration? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

echo -n "Which board do you want to enable? [dac/dacplus-std/dacplus-pro/dacplusadc/dacplusadcpro/dacplusdsp/digi/digipro/amp] "
read CARD
if [[ ! "$CARD" =~ ^(dac|dacplus.+|digi|amp)$ ]]; then exit 1; fi

rm -f ~/.asoundrc ~/.asound.conf ~/asound.conf

sudo tee /etc/asound.conf >/dev/null <<EOF
pcm.!default {
  type hw card 0
}
ctl.!default {
  type hw card 0
}
EOF


cat /boot/firmware/config.txt | grep -vi "dtparam=audio" | grep -vi "hifiberry" >/tmp/config.txt
sed -i -e s/dtoverlay=vc4-kms-v3d/dtoverlay=vc4-kms-v3d,noaudio/g /tmp/config.txt
echo dtoverlay=hifiberry-${CARD} >>/tmp/config.txt

sudo chown $(sudo id -u):$(sudo id -g) /tmp/config.txt
sudo mv /tmp/config.txt /boot/firmware/config.txt
