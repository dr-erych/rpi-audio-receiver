#!/bin/bash -e

echo
echo -n "Do you want to install Shairport Sync AirPlay 2 Audio Receiver (shairport-sync)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi


PRETTY_HOSTNAME=$(hostnamectl status --pretty)

# install packages needed by shairport
sudo apt install -y --no-install-recommends build-essential git autoconf automake libtool \
  libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev \
  libplist-dev libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt-dev xxd

if [[ -z "$TMP_DIR" ]]; then
    TMP_DIR=$(mktemp -d)
fi

cd $TMP_DIR

# Install ALAC
wget -O alac-master.zip https://github.com/mikebrady/alac/archive/refs/heads/master.zip
unzip alac-master.zip
cd alac-master
autoreconf -fi
./configure
make -j $(nproc)
sudo make install
sudo ldconfig
cd ..
rm -rf alac-master

# Install NQPTP
wget -O nqptp.zip https://github.com/mikebrady/nqptp/archive/refs/heads/main.zip
unzip nqptp.zip
cd nqptp
autoreconf -fi
./configure --with-systemd-startup
make -j $(nproc)
sudo make install
cd ..
rm -rf nqptp

# Install Shairport Sync
wget -O shairport-sync.zip https://github.com/mikebrady/shairport-sync/archive/refs/heads/master.zip
unzip shairport-sync.zip
cd shairport-sync
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2 --with-apple-alac
make -j $(nproc)
sudo make install
cd ..
rm -rf shairport-sync

# Configure Shairport Sync
sudo tee /etc/shairport-sync.conf >/dev/null <<EOF
general = {
  name = "${PRETTY_HOSTNAME:-$(hostname)}";
  output_backend = "alsa";
}

sessioncontrol = {
  session_timeout = 20;
};
EOF

sudo usermod -a -G gpio shairport-sync
sudo systemctl enable --now nqptp
sudo systemctl enable --now shairport-sync
