#!/bin/bash
#title           :init_auth.bash
#description     :IoT USB Key feature installation script
#author          :Nicholas Putra Rihandoko
#date            :2023/06/21
#version         :1.2
#usage           :Iot Gateway
#notes           :
#==============================================================================

## Configure IoT USB Key feature
# Enable execute (run program) privilege for all related files
sudo chmod +x /home/$(logname)/key_code/starter.py
sudo chmod +x /home/$(logname)/key_code/backup.py
sudo chmod +x /home/$(logname)/key_code/auth.py
sudo chmod +x /home/$(logname)/key_code/src/jobs.py
sudo chmod +x /home/$(logname)/key_code/src/get_usb.bash
sudo chmod +x /etc/crontab

## Create the dependency files
# File paths to create
file_paths=(
"/home/$(logname)/key_code/src/jobs.txt"
"/home/$(logname)/key_code/src/status.txt"
"/home/$(logname)/key_code/src/encryptor.txt"
"/home/$(logname)/key_code/src/keyword.txt"
"/home/$(logname)/key_code/iot_key.txt"
)
# Loop through the list of file paths
for file_path in "${file_paths[@]}"; do
# Check if the file already exists
if [ ! -e "$file_path" ]; then
# Create the file
echo "" > "$file_path"
fi
# Set the permissions
chmod 777 "$file_path"
done

## Install necessary packages:
sudo apt install python3-pip
sudo pip3 install pyudev
sudo pip3 install psutil
sudo pip3 install cryptography
sudo pip3 install pyzipper

## Run auth.py to configure keyword
sudo python3 /home/$(logname)/key_code/auth.py generate

## Configure automatic run for every reboot
# Enable Cron to automate task
sudo systemctl enable cron
# Create cron command to check connection every 2 minutes, stars dial.bash if there is no internet
line='*/2 * * * * root python3 /home/$(logname)/key_code/starter.py & >> /home/$(logname)/key_code/src/starter.log 2>&1'
# Check whether the command line already exists in /etc/crontab, add or uncomment it if it does not
sudo su -c "sed -i '/.*key_code.*/d' /etc/crontab"
sudo su -c "echo \"$line\" >> /etc/crontab"
# Restart cron service
sudo service cron restart && sudo systemctl restart cron
sleep 1
echo "Installation of IoT USB Key system is completed"
echo ""
python3 /home/$(logname)/key_code/starter.py &
exit
