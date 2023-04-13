#!/bin/bash

echo "SIM Card APN = "
read sim_apn
echo "SIM Card Username = "
read sim_user
echo "SIM Card Password = "
read sim_pass

# Enable execute (run program) privilege for all related files
sudo chmod +x /home/$(logname)/simhat_code/dial.txt
sudo chmod +x /home/$(logname)/simhat_code/dial.bash
sudo chmod +x /home/$(logname)/simhat_code/init_dial.txt
sudo chmod +x /home/$(logname)/simhat_code/init/init_dial.txt
sudo chmod +x /home/$(logname)/simhat_code/init/dial.bash

## Install necessary packages:
# minicom package for sending AT command to SIM card
sudo apt install minicom -y
# 7zip package to extract .7z files
sudo apt install p7zip-full -y
# kernel modules for the SIM Hat's driver
sudo apt install linux-headers-$(uname -r) -y
# udhcpc package for connecting to the internet
sudo apt install udhcpc -y

## Configure SIM Card
# Copy the default init_dial.txt file from init folder
sudo yes | cp -rf /home/$(logname)/simhat_code/init/init_dial.txt /home/$(logname)/simhat_code/init_dial.txt
# Write the AT command to configure the SIM card's APN, username, and password in the init_dial.txt file
sudo cat <<endoffile >> /home/$(logname)/simhat_code/init_dial.txt
sleep 1
send "ATE1\r"
sleep 1
send "AT+CUSBPIDSWITCH=9001,1,1\r"
sleep 1
send "AT+CCUART=0\r"
sleep 1
send "AT+CGDCONT=1,\"IP\",\"$sim_apn\"\r"
sleep 1
send "AT+CGAUTH=1,3,\"$sim_pass\",\"$sim_user\"\r"
sleep 1
send "AT+CGACT=1,3\r"
sleep 1
! killall -9 minicom
endoffile
# Run AT command in init_dial.txt through minicom to setup SIM Card's APN
sudo minicom -D /dev/ttyUSB2 -S /home/$(logname)/simhat_code/init_dial.txt -b 115200
sleep 1
echo ""
clear

## Configure internet access
# Extract the zip file (.7z)
sudo su -c "cd /home/$(logname)/simhat_code && 7z x SIM7600_NDIS.7z   -r -o./SIM7600_NDIS -y"
# Reset make files before compiling
sudo su -c "cd /home/$(logname)/simhat_code/SIM7600_NDIS && make clean"
# Run make files to compile SIM Hat driver
sudo su -c "cd /home/$(logname)/simhat_code/SIM7600_NDIS && make"
# Copy the default dial.bash file from init folder
sudo yes | cp -rf /home/$(logname)/simhat_code/init/dial.bash /home/$(logname)/simhat_code/dial.bash
# Write RaspberyPi's username-dependent command in dial.bash
sudo cat <<endoffile >> /home/$(logname)/simhat_code/dial.bash
# Wait for 5 seconds to make sure the rapsberry pi has completed its reboot sequence
sleep 5
# Remove the default Qualcomm SIM card driver (it will be automatically installed during every reboot)
sudo su -c "rmmod qmi_wwan" &
sleep 1
# Install the Simcom SIM card driver (it will be automatically removed during every reboot)
sudo su -c "cd /home/$(logname)/simhat_code/SIM7600_NDIS && insmod simcom_wwan.ko" &
sleep 1
# enable mobile data connection interface
sudo ifconfig wwan0 up
sleep 3
# Run AT command in dial.txt through minicom to setup start Internet Data Call
sudo minicom -D /dev/ttyUSB2 -S /home/$(logname)/simhat_code/dial.txt -b 115200
sleep 1
echo ""
clear
# Obtain public address to connect to the internet
sudo udhcpc -i wwan0
sleep 1
# fix DNS error if happened
sudo route add -net 0.0.0.0 wwan0
sleep 1
exit
endoffile
# Run dial.bash to configure internet data call
sudo bash /home/$(logname)/simhat_code/dial.bash
sleep 1

## Configure automatic run for every reboot
# install and enable Cron to automate task
sudo apt install cron
sudo systemctl enable cron
# Check whether the command line is already exist in /etc/crontab
if ! sudo grep -q "sudo bash /home/$(logname)/simhat_code/dial.bash &" /etc/crontab; then
    # Append the file into /etc/crontab to enable automatic run after reboot 
    sudo su -c "echo \"@reboot root sudo bash /home/$(logname)/simhat_code/dial.bash &\" >> /etc/crontab"
    # install 'Remote.it' desktop app for remote access
    sudo apt install /home/$(logname)/simhat_code/Remote.It-Installer-arm64.deb -y
fi
sleep 1
# Enable execute (run program) privilege /etc/crontab
sudo chmod +x /etc/crontab
sleep 1
echo "Installation of SIMHAT system is finished"
exit