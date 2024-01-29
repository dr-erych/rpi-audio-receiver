#!/bin/bash -e

PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

cat << EOF > $HOME/go-librespot-config.yml
device_name: $PRETTY_HOSTNAME
credentials:
  type: zeroconf
server_port: 5050
normalisation_disabled: true
EOF


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


DAEMON_BASE_URL=https://github.com/devgianlu/go-librespot/releases/download/v
VERSION=0.0.11
DAEMON_ARCHIVE=go-librespot_linux_$ARCH.tar.gz
DAEMON_DOWNLOAD_URL=$DAEMON_BASE_URL$VERSION/$DAEMON_ARCHIVE
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

# Data dir
DAEMON_DATA_PATH=/data/go-librespot/
[ -d $DAEMON_DATA_PATH ] || mkdir $DAEMON_DATA_PATH

echo 'Librespot-go daemon starting...'
/usr/bin/go-librespot -config_path $HOME/go-librespot-config.yml" | sudo tee /bin/start-go-librespot.sh

sudo chmod a+x /bin/start-go-librespot.sh

GROUP=$(id -gn)

echo "[Unit]
Description = go-librespot Daemon

[Service]
ExecStart=/bin/start-go-librespot.sh
Restart=always
RestartSec=3
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=go-librespot
User=$USER
Group=$GROUP
[Install]
WantedBy=multi-user.target" | sudo tee /lib/systemd/system/go-librespot-daemon.service

sudo systemctl daemon-reload
sudo systemctl enable go-librespot-daemon
sudo systemctl start go-librespot-daemon


#required to end the plugin install
echo "plugininstallend"

