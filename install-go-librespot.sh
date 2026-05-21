#!/bin/bash -e

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

GO_LIBRESPOT_VERSION="${GO_LIBRESPOT_VERSION:-$(wget -qO- https://api.github.com/repos/devgianlu/go-librespot/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)}"

if [ -z "$GO_LIBRESPOT_VERSION" ]; then
  echo "Could not determine the latest go-librespot release." >&2
  exit 1
fi

TARGET_USER=${SUDO_USER:-$USER}
TARGET_GROUP=$(id -gn "$TARGET_USER")
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  echo "Could not resolve home directory for user $TARGET_USER"
  exit 1
fi

TARGET_HOME=$(cd "$TARGET_HOME" && pwd -P)

CONFIG_DIR="$TARGET_HOME/.config/go-librespot"
sudo install -d -o "$TARGET_USER" -g "$TARGET_GROUP" "$CONFIG_DIR"
cat << EOF | sudo tee "$CONFIG_DIR/config.yml" > /dev/null
device_name: $PRETTY_HOSTNAME
initial_volume: 20
device_type: speaker
audio_backend: alsa
audio_device: default
EOF
sudo chown "$TARGET_USER:$TARGET_GROUP" "$CONFIG_DIR/config.yml"

ARCH=$(uname -m)

case "$ARCH" in
  armv6l)
    ARCH="armv6_rpi"
    ;;
  armv7l|armv8|armhf)
    ARCH="armv6"
    ;;
  arm64|aarch64)
    ARCH="arm64"
    ;;
  *)
    echo "Platform not supported"
    exit 1
    ;;
esac

echo "📦 Installing go-librespot ${GO_LIBRESPOT_VERSION}"
echo
sudo apt-get install -y libogg-dev libvorbis-dev libasound2-dev

DAEMON_BASE_URL="https://github.com/devgianlu/go-librespot/releases/download/$GO_LIBRESPOT_VERSION"
DAEMON_ARCHIVE="go-librespot_linux_$ARCH.tar.gz"
DAEMON_DOWNLOAD_URL="$DAEMON_BASE_URL/$DAEMON_ARCHIVE"
DAEMON_DOWNLOAD_PATH="/tmp/$DAEMON_ARCHIVE"

if sudo systemctl is-active --quiet go-librespot-daemon.service; then
  sudo systemctl stop go-librespot-daemon.service
fi
wget "$DAEMON_DOWNLOAD_URL" -O "$DAEMON_DOWNLOAD_PATH"
sudo tar xzf "$DAEMON_DOWNLOAD_PATH" -C /usr/bin go-librespot
rm "$DAEMON_DOWNLOAD_PATH"
sudo chown root:root /usr/bin/go-librespot
sudo chmod 755 /usr/bin/go-librespot
file /usr/bin/go-librespot

systemd_quote() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  printf '"%s"' "$value"
}

SYSTEMD_TARGET_HOME=$(systemd_quote "$TARGET_HOME")
SYSTEMD_CONFIG_DIR=$(systemd_quote "$CONFIG_DIR")
SYSTEMD_LOCKFILE=$(systemd_quote "$CONFIG_DIR/lockfile")

cat << EOF | sudo tee /lib/systemd/system/go-librespot-daemon.service > /dev/null
[Unit]
Description=go-librespot Daemon
Wants=network-online.target sound.target
After=network-online.target sound.target
RequiresMountsFor=$SYSTEMD_TARGET_HOME
StartLimitIntervalSec=0

[Service]
Type=exec
Environment=GOTRACEBACK=crash
ExecStartPre=/bin/rm -f $SYSTEMD_LOCKFILE
ExecStart=/usr/bin/go-librespot --config_dir $SYSTEMD_CONFIG_DIR
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=go-librespot
User=$TARGET_USER
SupplementaryGroups=audio
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable go-librespot-daemon
sudo systemd-analyze verify /lib/systemd/system/go-librespot-daemon.service
sudo systemctl restart go-librespot-daemon

echo
echo "✅ go-librespot installation complete."
