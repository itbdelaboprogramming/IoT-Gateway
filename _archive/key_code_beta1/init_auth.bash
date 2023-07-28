#!/bin/bash
#title           :init_auth.bash
#description     :IoT USB Key feature installation script
#author          :Nicholas Putra Rihandoko
#date            :2023/04/20
#version         :1.1
#usage           :Iot Gateway
#notes           :take a look at README.txt for further info
#==============================================================================

echo "Please input the new password for IoT USB Key feature"
read -p "password: " new_password
echo ""

## Configure IoT USB Key feature
# Enable execute (run program) privilege for all related files
sudo chmod +x /home/$(logname)/key_code/auth.py
sudo chmod +x /etc/crontab
# Install necessary packages:
sudo apt install python3-pip
sudo pip3 install pyudev
sudo pip3 install psutil
sudo pip3 install cryptography
# Run auth.bash to configure internet data call
echo ""
sudo python3 /home/$(logname)/key_code/auth.py generate new_password
sudo python3 /home/$(logname)/key_code/auth.py monitor

## Configure automatic run for every reboot
# Enable Cron to automate task
sudo systemctl enable cron
# Create cron command to check connection every 2 minutes, stars dial.bash if there is no internet
line='@reboot sleep 10 && root sudo bash /home/$(logname)/key_code/auth.py monitor & >> /home/$(logname)/key_code/monitor.log 2>&1'
# Check whether the command line already exists in /etc/crontab, add or uncomment it if it does not
sudo su -c "sed -i '/.*key_code.*/d' /etc/crontab"
sudo su -c "echo \"$line\" >> /etc/crontab"
# Restart cron service
sudo service cron restart && sudo systemctl restart cron
sleep 1
echo "Installation of IoT USB Key system is finished"
exit