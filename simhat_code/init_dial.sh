#!/bin/sh

# Enable execute (run program) privilege for all related files
sudo chmod +x /home/$(logname)/simhat_code/dial.txt
sudo chmod +x /home/$(logname)/simhat_code/dial.sh
sudo chmod +x /home/$(logname)/simhat_code/init_dial.txt
sleep 1
# Install minicom package for sending AT command to SIM card
sudo apt install minicom -y
sleep 1
# Run AT command in init_dial.txt through minicom to setup SIM Card's APN
minicom -D /dev/ttyUSB2 -S /home/$(logname)/simhat_code/init_dial.txt
sleep 1
# Install 7zip package to extract .7z files
sudo apt install p7zip-full -y
sleep 1
# Install kernel modules for the SIM Hat's driver
sudo apt install raspberrypi-kernel-headers -y
sleep 1
# Install udhcpc package for connecting to the internet
sudo apt install udhcpc -y
sleep 1
# Extract the zip file (.7z)
sudo su -c "cd /home/$(logname)/simhat_code && 7z x SIM7600_NDIS.7z   -r -o./SIM7600_NDIS -y"
sleep 1
# Reset make files before compiling
sudo su -c "cd /home/$(logname)/simhat_code/SIM7600_NDIS && make clean"
sleep 1
# Run make files to compile SIM Hat driver
sudo su -c "cd /home/$(logname)/simhat_code/SIM7600_NDIS && make"
sleep 1
# Run dial.sh to configure internet data call
sudo sh /home/$(logname)/simhat_code/dial.sh
sleep 1
# Check whether the command line is already exist in /etc/rc.local
if ! sudo grep -q "sudo sh /home/$(logname)/simhat_code/dial.sh &" /etc/rc.local; then
    # Append the file into /etc/rc.local (1 line above "exit 0") to enable automatic run after reboot 
    sudo sed -i "$(($(wc -l < /etc/rc.local)-0))i sudo sh /home/$(logname)/simhat_code/dial.sh &" /etc/rc.local
    # install 'Remote.it' desktop app for remote access
    sudo apt install /home/$(logname)/simhat_code/Remote.It-Installer-armv7l.deb -y
    sudo sed -i "$(($(wc -l < /etc/rc.local)-0))i sleep 5 && opt/Remote.It/remoteit &" /etc/rc.local
fi
sleep 1
# Enable execute (run program) privilege /etc/rc.local
sudo chmod +x /etc/rc.local
sleep 1
exit