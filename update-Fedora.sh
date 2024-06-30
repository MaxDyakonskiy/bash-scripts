#! /bin/sh
echo '------- DNF is updating -------'
sudo dnf check-update
wait
sudo dnf distro-sync -y
wait

echo '------- Flatpak is updating -------'
sudo flatpak update -y
wait

echo '------- Firmware is updating -------'
sudo fwupdmgr refresh
wait
sudo fwupdmgr update
wait

exit 0

