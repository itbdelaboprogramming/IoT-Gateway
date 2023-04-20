#!/bin/sh

echo "SIM Card APN = "
read sim_apn
echo "SIM Card Username = "
read sim_user
echo "SIM Card Password = "
read sim_pass

# Enable execute (run program) privilege for all related files
sudo chmod +x /home/$(logname)/simhat_code/dial.py
sudo chmod +x /home/$(logname)/simhat_code/dial.sh
sudo chmod +x /etc/crontab

## Install necessary packages:
# minicom package for AT command debugging
sudo apt install minicom -y
# python and pyserial for AT command programming
sudo apt install python3-pip -y
sudo pip3 install pyserial
# 7zip package to extract .7z files
sudo apt install p7zip-full -y
# kernel modules for the SIM Hat's driver
sudo apt install raspberrypi-kernel-headers -y
# udhcpc package for connecting to the internet
sudo apt install udhcpc -y
# cron for task automation
sudo apt install cron -y
# 'Remote.it' desktop app for remote access
#sudo apt install /home/$(logname)/simhat_code/Remote.It-Installer-armv7l.deb -y
# 'zerotier' for virtual LAN
sudo apt install curl -y
curl -s https://install.zerotier.com | sudo bash
# for 'router' opetration
sudo apt install nmap dnsmasq iptables -y

## Configure SIM Card
# Run AT command in dial.py to setup SIM Card's APN
sudo python3 /home/$(logname)/simhat_code/dial.py init_dial $sim_apn $sim_user $sim_pass

## Configure internet access
# Extract the zip file (.7z)
sudo su -c "cd /home/$(logname)/simhat_code && 7z x SIM7600_NDIS.7z   -r -o./SIM7600_NDIS -y"
# Write RaspberyPi's username-dependent command in dial.sh
sudo > /home/$(logname)/simhat_code/dial.sh
sudo cat <<endoffile >> /home/$(logname)/simhat_code/dial.sh
#!/bin/sh
# Ping the Google DNS server to check internet connectivity
if ! sudo ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
    # Run internet dial sequence
    sudo python3 /home/$(logname)/simhat_code/dial.py $(logname)
fi
exit 0
endoffile
# Run dial.sh to configure internet data call
sudo sh /home/$(logname)/simhat_code/dial.sh

## Configure automatic run for every reboot
# Enable Cron to automate task
sudo systemctl enable cron
# Create cron command to check connection every 2 minutes, stars dial.sh if there is no internet
line='*/2 * * * * root sudo sh /home/$(logname)/simhat_code/dial.sh >> /home/$(logname)/simhat_code/dial.log 2>&1'
# Check whether the command line already exists in /etc/crontab, add or uncomment it if it does not
sudo su -c "sed -i '/.*simhat_code.*/d' /etc/crontab"
sudo su -c "echo \"$line\" >> /etc/crontab"
# Restart cron service
sudo service cron restart && sudo systemctl restart cron 

echo ""
echo "============================================"
echo "Installation of SIMHAT system is finished"
echo "Please reboot the RaspberryPi"
echo "============================================"
exit 0