#!/bin/bash -e

sudo apt update
sudo apt upgrade -y

sudo apt-get -y install curl && curl -o madfu-firmware.zip -sL https://github.com/osxmidi/madfu-firmware-mirror/zipball/master
unzip madfu-firmware.zip -d ./madfu-firmware
cd madfu-firmware/*
./configure
make
make install
cd -
rm madfu-firmware.zip
rm -rf madfu-firmware/
alsactl kill rescan
AUDIO_OUT=$(aplay -l | grep -oP 'card\s([0-9]+):\sMobilePre' | grep -oP '[0-9]+')
USER=${SUDO_USER:-$(who -m | awk '{ print $1 }')}
ASPATH=$(getent passwd $USER | cut -d : -f 6)/.asoundrc
cat << EOF > $ASPATH
defaults.pcm.card $AUDIO_OUT
defaults.ctl.card $AUDIO_OUT

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
  card $AUDIO_OUT
}

ctl.!default {
  type hw
  card $AUDIO_OUT
}

EOF
