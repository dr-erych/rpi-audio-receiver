#!/bin/bash -e

TARGET_USER="${SUDO_USER:-$(id -un)}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  echo "Could not resolve home directory for user $TARGET_USER"
  exit 1
fi

echo "📦 Installing M-Audio MobilePre firmware"
echo
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

# Use the stable ALSA card name instead of a numeric card index.
# Numeric ALSA indexes such as card 0/card 1 can change depending on boot timing,
# especially after power loss. MobilePre is the expected USB audio interface.
cat << 'EOF' | sudo tee /etc/asound.conf > /dev/null
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
  type plug
  slave.pcm "hw:CARD=MobilePre,DEV=0"
}

pcm.input {
  type plug
  slave.pcm "hw:CARD=MobilePre,DEV=0"
}

ctl.!default {
  type hw
  card MobilePre
}
EOF

# ALSA loads ~/.asoundrc before /etc/asound.conf. Since go-librespot runs as the
# install user, an old ~/.asoundrc can override the system-wide MobilePre config
# and break playback.
if [ -f "$TARGET_HOME/.asoundrc" ]; then
  sudo mv "$TARGET_HOME/.asoundrc" "$TARGET_HOME/.asoundrc.backup.$(date +%Y%m%d-%H%M%S)"
fi

echo
echo "✅ M-Audio MobilePre setup complete."
echo "🔁 Reboot required: sudo reboot"
