## Raspberry Pi Audio Receiver

A simple, lightweight audio receiver with AirPlay 2 and Spotify Connect clients, adapted from [nicokaiser/rpi-audio-receiver](https://github.com/nicokaiser/rpi-audio-receiver) for Raspberry Pi Zero W setups.

## Features

Devices like phones, tablets and computers can play audio via this receiver.

## Requirements

- Raspberry Pi Zero W, Raspberry Pi Zero 2 W, or another Raspberry Pi with a supported CPU architecture
- Raspberry Pi OS Legacy
- Internal audio, HDMI, USB, or I2S audio adapter
- `wget` and `unzip` for the archive-based installation shown below

Tested with:

- [SABRENT USB External USB Sound Card](https://www.amazon.de/gp/product/B00IRVQ0F8/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&th=1)
- [HiFiBerry DAC+](https://www.hifiberry.com/products/dacplus/)
- M-Audio MobilePre USB audio interface

## Installation

Clone or download this branch, then run the setup scripts you need. Most scripts make system-level changes and install packages, so run them on a clean Raspberry Pi OS install.

```bash
wget -q https://github.com/dr-erych/rpi-audio-receiver/archive/rpi-zero-w.zip
unzip rpi-zero-w.zip
rm rpi-zero-w.zip

cd rpi-audio-receiver-rpi-zero-w

# Update packages, set hostname, and set the visible device name.
./initialize.sh

# Sound card setup, depending on your hardware.
./enable-hifiberry.sh       # HiFiBerry I2S boards
./enable-usb-audio.sh       # Generic USB audio adapters
./install-maudio-driver.sh  # M-Audio MobilePre USB

# Spotify Connect. Pick one.
./install-go-librespot.sh   # Raspberry Pi Zero W v1.x and other non-arm64 installs
./install-raspotify.sh      # arm64 Raspberry Pi OS only

# AirPlay 2.
./install-shairport-sync.sh
```

Reboot after setup so hostname, audio, and service changes are applied consistently:

```bash
sudo reboot
```

### Basic setup

`initialize.sh` lets you choose the hostname and visible device name ("pretty hostname") used by AirPlay and Spotify clients. It also updates packages and points `/etc/asound.conf` at the current user's `~/.asoundrc`.

### AirPlay 2

`install-shairport-sync.sh` builds and installs [Shairport Sync](https://github.com/mikebrady/shairport-sync) with AirPlay 2 support, plus [NQPTP](https://github.com/mikebrady/nqptp) for timing support.

### Spotify Connect

Depending on your system, install either go-librespot or Raspotify.

- `install-go-librespot.sh` downloads the latest go-librespot release for `armv6l`, `armv7l`, `armhf`, or `arm64`/`aarch64`, writes `~/.config/go-librespot/config.yml`, and installs a `go-librespot-daemon` systemd service.
- `install-raspotify.sh` only supports `arm64`/`aarch64`. It uses the upstream Raspotify install script and then sets the device name and initial volume.

## Troubleshooting

### Spotify sees the MobilePre receiver, but playback fails after a power cut

If Spotify can see the device but playback fails with:

```text
ALSA error at snd_pcm_open: Unknown error 524
```

check the ALSA devices, system-wide ALSA config, and go-librespot logs:

```bash
aplay -l
cat /etc/asound.conf
journalctl -u go-librespot-daemon -b --no-pager -n 80
```

`/etc/asound.conf` should target `CARD=MobilePre`, not `card 0`. ALSA numeric card indexes can change across boots, especially after power loss. `go-librespot` should use `audio_device: default`, and ALSA should define the default device as the MobilePre.

Basic service checks:

```bash
systemctl status go-librespot-daemon --no-pager -l
journalctl -u go-librespot-daemon -b --no-pager -n 80
```

## Disclaimer

These scripts are tested and work on a current Raspberry Pi OS Legacy setup on Raspberry Pi Zero W 1. Depending on your setup (board, configuration, sound module) and your preferences, you might need to adjust the scripts. They are held as simple as possible and can be used as a starting point for additional adjustments.

## Upgrading

This project does not really support upgrading to newer versions of these scripts. It is meant to be adjusted to your needs and run on a clean Raspberry Pi OS install. When something goes wrong, the easiest way is usually to wipe the SD card and start over. Keep a copy of any local changes first, especially audio configuration and go-librespot settings.

Updating the system using `apt-get upgrade` should work however.

## Uninstallation

This project does not support uninstall at all. As stated above, it is meant to run on a dedicated device on a clean Raspberry Pi OS. If you choose to use this script along with other services on the same device, or install it on an already configured device, this can lead to unpredictable behaviour and can damage the existing installation permanently.
However, the important modules can be removed with the following commands. This does not remove every build dependency or source-install residual file and is experimental:

```bash
sudo systemctl disable --now shairport-sync nqptp
sudo rm -f /etc/shairport-sync.conf
sudo rm -f /usr/local/bin/shairport-sync /usr/local/bin/nqptp
sudo rm -f /lib/systemd/system/shairport-sync.service /lib/systemd/system/nqptp.service

sudo apt purge -y raspotify
sudo rm -f /etc/apt/sources.list.d/raspotify.list
sudo rm -f /usr/share/keyrings/raspotify_key.asc

sudo systemctl disable --now go-librespot-daemon.service
sudo rm -f /lib/systemd/system/go-librespot-daemon.service
sudo rm -f /usr/bin/go-librespot
rm -rf ~/.config/go-librespot
sudo systemctl daemon-reload

sudo rm -f /etc/asound.conf
sudo rm -f /etc/modprobe.d/blacklist-onboard-audio.conf
sudo sed -e '/options snd-usb-audio index=-2/ s/^#*//' -i /lib/modprobe.d/aliases.conf
```

HiFiBerry setup also edits `/boot/firmware/config.txt`. To undo it, remove the `dtoverlay=hifiberry-...` line and remove the `,noaudio` suffix from `dtoverlay=vc4-kms-v3d,noaudio`.

The initial setup may also change the hostname and pretty hostname. Change them back with `sudo raspi-config` and `sudo hostnamectl set-hostname --pretty "Raspberry Pi"` if needed.

[The Shairport Sync installation guide](https://github.com/mikebrady/shairport-sync/blob/master/INSTALL.md) gives more information on residual files that could be checked for removal.


## Contributing

Package and configuration choices are quite opinionated but as close to the Debian defaults as possible. Customizations can be made by modifying the scripts, but the installer should stay as simple as possible, with as few choices as possible. That said, pull requests and suggestions are of course always welcome. However I might decide not to merge changes that add too much complexity.

## References

- [Shairport Sync: AirPlay Audio Receiver](https://github.com/mikebrady/shairport-sync)
- [Raspotify: Spotify Connect client for the Raspberry Pi that Just Works™](https://github.com/dtcooper/raspotify)
- [Go Librespot: Yet another open-source Spotify Connect compatible client, written in Go.](https://github.com/devgianlu/go-librespot)

## License

[MIT](LICENSE)
