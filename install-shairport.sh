#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo -n "Do you want to install Shairport Sync AirPlay 2 Audio Receiver (shairport-sync)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

# install packages needed by shairport
apt install -y --no-install-recommends build-essential git autoconf automake libtool \
    libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev \
    libplist-dev libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt-dev xxd

# install alac
git clone https://github.com/mikebrady/alac.git
cd alac
autoreconf -fi
./configure
make
make install
ldconfig
cd ..
rm -rf alac

# install nqptp
git clone https://github.com/mikebrady/nqptp.git
cd nqptp
autoreconf -fi
./configure --with-systemd-startup
make
make install
cd ..
rm -rf nqptp

# install shairport-sync
git clone https://github.com/mikebrady/shairport-sync.git
cd shairport-sync
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa \
  --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2
make
make install
cd ..
rm -rf shairport-sync

# set some important settings
PRETTY_HOSTNAME=$(hostnamectl status --pretty)
PRETTY_HOSTNAME=${PRETTY_HOSTNAME:-$(hostname)}

sed -i '0,/%H/{s://\tname = "%H:\tname = "'"${PRETTY_HOSTNAME}"':}' /etc/shairport-sync.conf
sed -i 's://\tinterpolation = "auto:\tinterpolation = "basic:' /etc/shairport-sync.conf

systemctl enable --now shairport-sync
