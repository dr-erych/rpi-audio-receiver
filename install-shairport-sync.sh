#!/bin/bash -e

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

latest_stable_tag() {
  local repo="$1"
  local tag

  tag=$(wget -qO- "https://api.github.com/repos/${repo}/tags?per_page=100" \
    | sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' \
    | grep -E '^[0-9]+([.][0-9]+)*$' \
    | sort -V \
    | tail -n 1)

  if [ -z "$tag" ]; then
    echo "Could not determine the latest stable tag for ${repo}." >&2
    exit 1
  fi

  printf '%s\n' "$tag"
}

download_release_archive() {
  local repo="$1"
  local tag="$2"
  local directory="$3"

  mkdir "$directory"
  wget -qO "${directory}.tar.gz" "https://github.com/${repo}/archive/refs/tags/${tag}.tar.gz"
  tar xzf "${directory}.tar.gz" -C "$directory" --strip-components=1
}

# install packages needed by shairport
echo "📦 Installing Shairport Sync build dependencies"
echo
sudo apt install -y --no-install-recommends build-essential wget autoconf automake libtool \
  libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev \
  libplist-dev libplist-utils libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt-dev xxd

NQPTP_VERSION="${NQPTP_VERSION:-$(latest_stable_tag mikebrady/nqptp)}"
SHAIRPORT_SYNC_VERSION="${SHAIRPORT_SYNC_VERSION:-$(latest_stable_tag mikebrady/shairport-sync)}"

echo "📦 Installing NQPTP ${NQPTP_VERSION}"
echo "📦 Installing Shairport Sync ${SHAIRPORT_SYNC_VERSION}"
echo

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"

# Shairport Sync 5 and recent NQPTP releases install updated systemd units.
# Remove older unit files first so systemd does not keep using stale startup rules.
sudo systemctl stop shairport-sync nqptp 2>/dev/null || true
sudo rm -f \
  /etc/systemd/system/shairport-sync.service \
  /etc/systemd/user/shairport-sync.service \
  /lib/systemd/system/shairport-sync.service \
  /lib/systemd/user/shairport-sync.service \
  /usr/local/lib/systemd/system/shairport-sync.service \
  /usr/local/lib/systemd/user/shairport-sync.service \
  /etc/dbus-1/system.d/shairport-sync-dbus.conf \
  /etc/dbus-1/system.d/shairport-sync-mpris.conf \
  /etc/init.d/shairport-sync \
  /lib/systemd/system/nqptp.service \
  /usr/local/lib/systemd/system/nqptp.service
sudo systemctl daemon-reload

# Older installs built the deprecated Apple ALAC library from source.
sudo rm -rf /usr/local/include/alac
sudo rm -f /usr/local/bin/alacconvert /usr/local/lib/libalac.* /usr/local/lib/pkgconfig/alac.pc
sudo ldconfig

# Install NQPTP
download_release_archive mikebrady/nqptp "$NQPTP_VERSION" nqptp
cd nqptp
autoreconf -fi
./configure --with-systemd-startup
make -j "$(nproc)"
sudo make install
sudo systemctl enable nqptp
sudo systemctl restart nqptp
cd ..

# Install Shairport Sync
download_release_archive mikebrady/shairport-sync "$SHAIRPORT_SYNC_VERSION" shairport-sync
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
  interpolation = "vernier";
  six_channel_mode = "off";
  eight_channel_mode = "off";
}

sessioncontrol = {
  session_timeout = 20;
};
EOF

sudo usermod -a -G gpio shairport-sync
sudo systemctl daemon-reload
sudo systemctl enable shairport-sync
sudo systemctl restart shairport-sync

echo
echo "✅ Shairport Sync installation complete."
