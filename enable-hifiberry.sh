#!/bin/bash -e

echo
echo -n "Do you want to enable HiFiBerry device tree overlay and ALSA configuration? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

echo -n "Which board do you want to enable? [dac/dacplus/dacplusadc/dacplusadcpro/dacplusdsp/digi/digipro/amp] "
read CARD
if [[ ! "$CARD" =~ ^(dac|dacplus|digi|amp)$ ]]; then exit 1; fi

sudo tee /etc/asound.conf >/dev/null <<EOF
pcm.!default {
  type asym
  playback.pcm {
    type plug
    slave.pcm "output"
  }
  capture.pcm {
    type plug
    slave.pcm "input"
  }
}

pcm.output {
  type hw
  card 1
}

ctl.!default {
  type hw
  card 1
}
EOF

sudo amixer sset 'Softvol' 100%
sudo alsactl store

cat /boot/config.txt | grep -vi "dtparam=audio" | grep -vi hifiberry >/tmp/config.txt
echo dtoverlay=hifiberry-${CARD} >>/tmp/config.txt
sudo chown $(sudo id -u):$(sudo id -g) /tmp/config.txt
sudo mv /tmp/config.txt /boot/config.txt
