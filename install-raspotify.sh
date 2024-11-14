#!/bin/bash -e

ARCH=$(uname -m)
if  [ $ARCH = "arm64" ] || [ $ARCH = "aarch64" ]; then
	ARCH="arm64"
else
	echo "Platform not supported. Only arm64 is supported by raspotify. Consider installing go-librespot instead." 
  exit 1
fi

echo
echo -n "Do you want to install Spotify Connect (Raspotify)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

sudo apt-get -y install curl && curl -sL https://dtcooper.github.io/raspotify/install.sh | sh

PRETTY_HOSTNAME=$(hostnamectl status --pretty | tr ' ' '-')
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

# change settings to work for raspberry pi zero
sed -i 's:#LIBRESPOT_NAME="Librespot:LIBRESPOT_NAME="'"${PRETTY_HOSTNAME}"':' /etc/raspotify/conf
sed -i 's:#LIBRESPOT_INITIAL_VOLUME="50":LIBRESPOT_INITIAL_VOLUME="20":' /etc/raspotify/conf

systemctl restart raspotify
