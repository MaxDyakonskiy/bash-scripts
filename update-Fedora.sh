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

# Uncomment it to update all pip packages at once.
# This is really bad idea 'cause it can break
# a multitude of Python modules and packages on your system.

# echo '------- Python packages is updating -------'
# pip list --outdated | cut -d ' ' -f 1 | tail -n +3 | xargs --interactive -d '\n' pip install -U

exit 0

