echo 'blacklist snd_bcm2835' | sudo tee /etc/modprobe.d/blacklist-onboard-audio.conf
sudo sed -e '/options snd-usb-audio index=-2/ s/^#*/#/' -i /lib/modprobe.d/aliases.conf

echo "Please reboot now."

