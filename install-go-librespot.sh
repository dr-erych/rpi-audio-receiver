#!/bin/bash -e

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

TARGET_USER=$USER
TARGET_GROUP=$(id -gn)
TARGET_HOME=$(cd "$HOME" && pwd -P)

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  echo "Could not resolve home directory for user $TARGET_USER"
  exit 1
fi

CONFIG_DIR=$HOME/.config/go-librespot
sudo install -d -o "$TARGET_USER" -g "$TARGET_GROUP" "$CONFIG_DIR"
cat << EOF | sudo tee "$CONFIG_DIR/config.yml" > /dev/null
device_name: $PRETTY_HOSTNAME
initial_volume: 20
device_type: speaker
EOF
sudo chown "$TARGET_USER:$TARGET_GROUP" "$CONFIG_DIR/config.yml"


echo "Installing Go-librespot"

ARCH=$(uname -m)

if [ $ARCH = "armv6l" ]; then
	ARCH="armv6_rpi"
elif [ $ARCH = "armv7l" ] || [ $ARCH = "armv8" ] || [ $ARCH = "armhf" ]; then
  ARCH="armv6"
elif  [ $ARCH = "arm64" ] || [ $ARCH = "aarch64" ]; then
	ARCH="arm64"
else
	echo "Platform not supported" 
  exit 1
fi

sudo apt-get install -y libogg-dev libvorbis-dev libasound2-dev

DAEMON_BASE_URL=https://github.com/devgianlu/go-librespot/releases/latest/download/
DAEMON_ARCHIVE=go-librespot_linux_$ARCH.tar.gz
DAEMON_DOWNLOAD_URL=$DAEMON_BASE_URL/$DAEMON_ARCHIVE
DAEMON_DOWNLOAD_PATH=$DAEMON_ARCHIVE

echo "Dowloading daemon"
if sudo systemctl is-active go-librespot-daemon.service; then
  sudo systemctl stop go-librespot-daemon.service
fi
wget $DAEMON_DOWNLOAD_URL -O $DAEMON_DOWNLOAD_PATH
sudo tar xf $DAEMON_DOWNLOAD_PATH -C /usr/bin/ go-librespot
rm $DAEMON_DOWNLOAD_PATH
sudo chmod a+x /usr/bin/go-librespot

echo "Creating Start Script"

echo "#!/bin/sh

# Traceback Setting
export GOTRACEBACK=crash

echo 'Librespot-go daemon starting...'
/usr/bin/go-librespot --config_dir $CONFIG_DIR" | sudo tee /bin/start-go-librespot.sh

sudo chmod a+x /bin/start-go-librespot.sh

systemd_quote() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  printf '"%s"' "$value"
}

SYSTEMD_TARGET_HOME=$(systemd_quote "$TARGET_HOME")
SYSTEMD_CONFIG_DIR=$(systemd_quote "$CONFIG_DIR")
SYSTEMD_LOCKFILE=$(systemd_quote "$CONFIG_DIR/lockfile")

echo "[Unit]
Description = go-librespot Daemon
Wants=network-online.target sound.target
After=network-online.target sound.target
RequiresMountsFor=$SYSTEMD_TARGET_HOME

[Service]
Environment=GOTRACEBACK=crash
ExecStartPre=/bin/rm -f $SYSTEMD_LOCKFILE
ExecStart=/usr/bin/go-librespot --config_dir $SYSTEMD_CONFIG_DIR
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=go-librespot
User=$TARGET_USER
Group=$TARGET_GROUP
[Install]
WantedBy=multi-user.target" | sudo tee /lib/systemd/system/go-librespot-daemon.service

sudo systemctl daemon-reload
sudo systemctl enable go-librespot-daemon
sudo systemd-analyze verify /lib/systemd/system/go-librespot-daemon.service
sudo systemctl restart go-librespot-daemon


#required to end the plugin install
echo "plugininstallend"
