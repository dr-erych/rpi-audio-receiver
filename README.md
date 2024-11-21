## Raspberry Pi Audio Receiver - Fork of Project from Nicokaiser working for raspberry pi zero w

A simple, light weight audio receiver with AirPlay 2 and Spotify Connect client.
Original repository can be found [here](https://github.com/nicokaiser/rpi-audio-receiver).

## Features

Devices like phones, tablets and computers can play audio via this receiver.

## Requirements

- RaspberryPi Zero W or Zero W 2
- Internal audio, HDMI, USB or I2S Audio adapter (tested with [SABRENT USB External USB Sound Card](https://www.amazon.de/gp/product/B00IRVQ0F8/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&th=1) and [HifiBerry DAC+](https://www.hifiberry.com/products/dacplus/))

## Installation

The installation script asks whether to install each component.

    wget -q https://github.com/dr-erych/rpi-audio-receiver/archive/rpi-zero-w.zip && unzip rpi-zero-w.zip && rm rpi-zero-w.zip

    cd rpi-audio-receiver-rpi-zero-w

    // Update packages and set pretty hostname
    $ ./initialize.sh

    // Sound card
    // depeding on your needs, one of the following:
    $ ./enable-hifiberry.sh
    $ ./enable-usb-audio.sh
    $ ./install-maudio-drivers.sh

    // Spotify Connect
    $ ./install-go-librespot.sh  // for Raspberry Pi Zero W v1.x
    $ ./install-raspotify.sh     // for Raspberry Pi Zero W 2 and Raspberry Pi >= 2

    // Airplay 2
    $ ./install-shairport-sync.sh
    
All effects should come into play after restarting the device (mainly the device hostname).

### Basic setup

Lets you choose the hostname and the visible device name ("pretty hostname") which is displayed in AirPlay clients and in Spotify.

### AirPlay 2

Installs [Shairport Sync](https://github.com/mikebrady/shairport-sync) AirPlay 2 Audio Receiver with all components needed to allow Synchronized Audio.

### Spotify Connect

Depending on your system, install go-librespot or raspotify.

## Disclaimer

These scripts are tested and work on a current Raspberry Pi OS Legacy setup on Raspberry Pi Zero W 1. Depending on your setup (board, configuration, sound module) and your preferences, you might need to adjust the scripts. They are held as simple as possible and can be used as a starting point for additional adjustments.

## Upgrading

This project does not really support upgrading to newer versions of this script. It is meant to be adjusted to your needs and run on a clean Raspberry Pi OS install. When something goes wrong, the easiest way is to just wipe the SD card and start over. Since apart from Bluetooth pairing information all parts are stateless, this should be ok.

Updating the system using `apt-get upgrade` should work however.

## Uninstallation

This project does not support uninstall at all. As stated above, it is meant to run on a dedicated device on a clean Raspberry Pi OS. If you choose to use this script along with other services on the same device, or install it on an already configured device, this can lead to unpredictable behaviour and can damage the existing installation permanently.
However, the important modules can be purged with the following commands. This does however not remove residual files and is experimental:

    sudo apt-get purge raspotify shairport-sync

[This site](https://github.com/mikebrady/shairport-sync/blob/master/INSTALL.md) gives information on residual files of shairplay which could be checked for removal.


## Contributing

Package and configuration choices are quite opinionated but as close to the Debian defaults as possible. Customizations can be made by modifying the scripts, but the installer should stay as simple as possible, with as few choices as possible. That said, pull requests and suggestions are of course always welcome. However I might decide not to merge changes that add too much complexity.

## References

- [Shairport Sync: AirPlay Audio Receiver](https://github.com/mikebrady/shairport-sync)
- [Raspotify: Spotify Connect client for the Raspberry Pi that Just Works™](https://github.com/dtcooper/raspotify)
- [Go Librespot: Yet another open-source Spotify Connect compatible client, written in Go.](https://github.com/devgianlu/go-librespot)

## License

[MIT](LICENSE)
