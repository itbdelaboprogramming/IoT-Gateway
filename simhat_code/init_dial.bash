#!/bin/bash
#title           :init_dial.bash
#description     :SIMHAT module installation script (main)
#author          :Nicholas Putra Rihandoko
#date            :2023/06/12
#version         :1.1
#usage           :Iot Gateway
#notes           :
#==============================================================================

echo ""
echo "Please input the SIM card's APN information"
echo "Press 'Enter' for empty Username or Password"
echo ""
read -p "SIM Card APN: " sim_apn
read -p "SIM Card Username: " sim_user
read -p "SIM Card Password: " sim_pass
echo ""
echo "Starting SIM Card configuration..."
echo ""
echo "Press 'ctrl + C' to cancel"
sleep 2
echo ""

# Enable execute (run program) privilege for all related files
sudo chmod +x /home/$(logname)/simhat_code/dial.py
sudo chmod +x /home/$(logname)/simhat_code/route.bash
sudo chmod +x /etc/crontab

## Install necessary packages:
# minicom and pyserial for AT command debugging and programming
sudo apt install minicom python3-pip -y
sudo pip3 install pyserial
# 7zip package to extract .7z files
sudo apt install p7zip-full -y
# kernel modules for the SIM Hat's driver
sudo apt install linux-headers-$(uname -r) -y
sudo apt install raspberrypi-kernel-headers -y
# udhcpc package for connecting to the internet
sudo apt install udhcpc -y
# 'zerotier' for virtual LAN and remote access
sudo apt install net-tools nmap -y
sudo apt install curl -y
curl -s https://install.zerotier.com | sudo bash
# cron for task automation
sudo apt install cron -y

## Configure remote access
# Join the ZeroTier network
echo ""
echo "This machine needs to join ZeroTier network to enable remote access"
while true; do
read -p "Do you want to configure it now? (y/n): " yn_zerotier
case $yn_zerotier in
[Yy]*)
read -p "Please input the ZeroTier Network_ID: " zt_net_id
sudo zerotier-cli join $zt_net_id
echo ""

while true; do
read -p "Do you want this machine to join another ZeroTier network? (y/n): " yn_zerotier
case $yn_zerotier in
[Yy]*)
read -p "Please input the ZeroTier Network_ID: " zt_net_id
sudo zerotier-cli join $zt_net_id
echo "";;
[Nn]*)
echo "OK, continuing."
break;;
*)
echo "Invalid input. Please answer 'y' or 'n'.";;
esac
done
break;;

[Nn]*)
echo "OK, continuing."
break;;
*)
echo "Invalid input. Please answer 'y' or 'n'.";;
esac
done
echo ""
echo "Here is your machine's ZeroTier network information:"
sudo zerotier-cli listnetworks
echo ""
echo "Please authorize this machine in the ZeroTier Central network settings [my.zerotier.com]."
echo ""
echo "Continuing with SIM Card and internet configuration..."

#=================================================
# CONNECTING TO THE INTERNET

## Configure SIM Card
# Run AT command in dial.py to setup SIM Card's APN
sudo python3 /home/$(logname)/simhat_code/dial.py config $sim_apn $sim_user $sim_pass

## Configure internet access
# Extract the zip file (.7z)
sudo su -c "cd /home/$(logname)/simhat_code && 7z x SIM7600_NDIS.7z   -r -o./SIM7600_NDIS -y"
# Write RaspberyPi's username-dependent command in dial.bash
sudo > /home/$(logname)/simhat_code/dial.bash
sudo cat <<endoffile >> /home/$(logname)/simhat_code/dial.bash
#!/bin/bash
echo ""
date +"%Y-%m-%d %H:%M:%S"
echo ""
# Ping the Google DNS server to check internet connectivity
if ! sudo ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
echo "NO INTERNET"
# Run internet dial sequence
sudo python3 /home/$(logname)/simhat_code/dial.py lease
fi
exit 0
endoffile
sudo chmod +x /home/$(logname)/simhat_code/dial.bash

# Run dial.py to initialize internet data call
lease=$(sudo python3 /home/$(logname)/simhat_code/dial.py lease | tail -1)
if [[ "$lease" == "ERROR" ]]; then
echo ""
echo "SIM Hat system installation incomplete"
echo "Exiting..."
echo ""
exit 0
fi

## Configure automatic run for every reboot
# Enable Cron to automate task
sudo systemctl enable cron
# Create cron command to check connection every 2 minutes, stars dial.bash if there is no internet
line='*/2 * * * * root sudo bash /home/$(logname)/simhat_code/dial.bash >> /home/$(logname)/simhat_code/dial.log 2>&1'
# Check whether the command line already exists in /etc/crontab, add or uncomment it if it does not
sudo su -c "sed -i '/.*simhat_code.*/d' /etc/crontab"
sudo su -c "echo \"$line\" >> /etc/crontab"
# Restart cron service
sudo service cron restart

#=================================================
# RASPBERRY PI AS ROUTER

while true; do
echo ""
read -p "Will this machine act as a router? (y/n): " yn_router
case $yn_router in
[Yy]*) 
echo ""
# Install packages for 'router' operation and debugging
sudo apt install dnsmasq iptables iptables-persistent -y

# Input 'router' subnet address
echo ""
echo "Your Raspberry Pi will manage local network (ethernet) route 172.21.xxx.0/24"
echo "with subnet xxx being between the value 2-254"
echo "and different with other Raspberry Pi routers in ZeroTier network"
read -p "Type in the value of subnet xxx: " subnet

# Run route.bash to configure routing operation
sudo bash /home/$(logname)/simhat_code/route.bash $zt_iface $subnet

# Write RaspberyPi's subnet-dependent command in dial.bash
sudo su -c "sed -i '/.*exit.*/d' /home/$(logname)/simhat_code/dial.bash"
echo -e "
echo \"\"
# Run route.bash if no hosts are up (RasPi-as-Router LAN's network)
if ! [ \$(sudo nmap -sP 172.21.$subnet.0/24 | grep \"Host is up\" | wc -l) -gt 1 ]; then
echo \"NO ROUTING FUNCTION\"
sudo bash /home/$(logname)/simhat_code/route.bash $zt_iface $subnet
fi
exit 0" | sudo tee -a /home/$(logname)/simhat_code/dial.bash &> /dev/null

echo ""
echo "=========================================================="
echo "Installation of Raspberry Pi as Router system is finished"
echo "The LAN's default gateway is 172.21.$subnet.1"
echo "with Subnet Mask 255.255.255.0 and DNS Server 8.8.8.8 (Google)"
echo "for up to 20 devices"

echo "----------------------------------------------------------"
echo "Follow these steps to route between ZeroTier network"
echo " and this machine's local network (ethernet)"
echo ""
echo "Open my.zerotier.com/network/\$NETWORK_ID"
echo "Go to Settings -> Advanced -> Managed Routes"
echo "Fill in the \"Add Routes\" parameters:"
echo "Destination = 172.21.$subnet.0/23"
echo "Via = 172.21.$subnet.1"
echo "Click \"Submit\""
echo "Go to Members, search for this machine's address ($(echo "$(sudo zerotier-cli info)" | awk '{print $3}'))"
echo "On the \"Managed IPs\" column, add IP address: 172.21.$subnet.1"
break;;

[Nn]*) 
echo ""
echo "=========================================================="
echo "Installation of SIMHAT system is finished"
break;;

*)
echo "Invalid input. Please answer 'y' or 'n'.";;
esac
done

echo ""
echo "Please reboot the RaspberryPi"
echo "=========================================================="
echo ""
exit 0