#!/bin/bash -e

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

NQPTP_VERSION="${NQPTP_VERSION:-main}"
SHAIRPORT_SYNC_VERSION="${SHAIRPORT_SYNC_VERSION:-master}"

# install packages needed by shairport
sudo apt install -y --no-install-recommends build-essential git autoconf automake libtool \
  libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev \
  libplist-dev libplist-utils libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt-dev xxd

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"

# Install NQPTP
git clone --depth 1 --branch "$NQPTP_VERSION" https://github.com/mikebrady/nqptp.git nqptp
cd nqptp
autoreconf -fi
./configure --with-systemd-startup
make -j "$(nproc)"
sudo make install
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/nqptp
sudo systemctl enable nqptp
sudo systemctl restart nqptp
cd ..

# Install Shairport Sync
git clone --depth 1 --branch "$SHAIRPORT_SYNC_VERSION" https://github.com/mikebrady/shairport-sync.git shairport-sync
cd shairport-sync
autoreconf -fi
./configure \
  --sysconfdir=/etc \
  --with-alsa \
  --with-soxr \
  --with-avahi \
  --with-ssl=openssl \
  --with-systemd-startup \
  --with-airplay-2
make -j "$(nproc)"
sudo make install
cd ..

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
sudo systemctl daemon-reload
sudo systemctl enable shairport-sync
sudo systemctl restart shairport-sync
