#!/bin/bash
#title           :init_dial.bash
#description     :SIMHAT module installation script (main)
#author          :Nicholas Putra Rihandoko
#date            :2023/04/20
#version         :1.1
#usage           :Iot Gateway
#notes           :take a look at README.txt for further info
#==============================================================================

echo ""
echo "Please input the SIM card's APN information"
read -p "SIM Card APN: " sim_apn
read -p "SIM Card Username: " sim_user
read -p "SIM Card Password: " sim_pass
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
sudo apt install raspberrypi-kernel-headers -y
sudo apt install linux-headers-$(uname -r) -y
# udhcpc package for connecting to the internet
sudo apt install udhcpc -y
# 'zerotier' for virtual LAN and remote access
sudo apt install net-tools -y
sudo apt install curl -y
curl -s https://install.zerotier.com | sudo bash
# cron for task automation
sudo apt install cron -y

## Configure remote access
echo ""
echo "This machine needs to join ZeroTier network to enable remote access"
read -p "Please input the ZeroTier Network ID: " zt_net_id
# Join the ZeroTier network
sudo zerotier-cli join $zt_net_id
echo ""
echo "Please input the ZeroTier Network's LAN managed route  " 
read -p "(ex: 192.168.200.0/23): " zt_net_route
zt_net_route=$(echo "$zt_net_route" | awk -F"." '{print $1"."$2"."$3}')
echo ""
echo "Please authorize this machine in the [my.zerotier.com] network settings"
echo ""

#=================================================
# CONNECTING TO THE INTERNET

## Configure SIM Card
# Run AT command in dial.py to setup SIM Card's APN
sudo python3 /home/$(logname)/simhat_code/dial.py init_dial $sim_apn $sim_user $sim_pass

## Configure internet access
# Extract the zip file (.7z)
sudo su -c "cd /home/$(logname)/simhat_code && 7z x SIM7600_NDIS.7z   -r -o./SIM7600_NDIS -y"
# Write RaspberyPi's username-dependent command in dial.bash
sudo > /home/$(logname)/simhat_code/dial.bash
sudo cat <<endoffile >> /home/$(logname)/simhat_code/dial.bash
#!/bin/bash
echo ""
# Ping the Google DNS server to check internet connectivity
if ! sudo ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
echo "NO INTERNET"
# Run internet dial sequence
sudo python3 /home/$(logname)/simhat_code/dial.py $(logname)
fi

# Count the number of hosts in a subnet (ZeroTier's network)
host_count=0
for host in {1..254}; do
host_ip="$zt_net_route.\$host"
if ! arp -n \$host_ip | grep -q "no entry"; then
host_count=\$((host_count+1))
fi
done
echo ""
# Restart ZeroTier service if no hosts are up (ZeroTier's network)
if ! [ \$host_count -gt 0 ]; then
echo "NO REMOTE ACCESS"
# Stop virtual LAN service
sudo service zerotier-one stop && sudo systemctl stop zerotier-one
# Start virtual LAN service
sudo service zerotier-one start && sudo systemctl start zerotier-one
fi
exit 0
endoffile
# Run dial.bash to configure internet data call
sudo chmod +x /home/$(logname)/simhat_code/dial.bash
sudo bash /home/$(logname)/simhat_code/dial.bash

## Configure automatic run for every reboot
# Enable Cron to automate task
sudo systemctl enable cron
# Create cron command to check connection every 2 minutes, stars dial.bash if there is no internet
line='*/2 * * * * root sudo bash /home/$(logname)/simhat_code/dial.bash >> /home/$(logname)/simhat_code/dial.log 2>&1'
# Check whether the command line already exists in /etc/crontab, add or uncomment it if it does not
sudo su -c "sed -i '/.*simhat_code.*/d' /etc/crontab"
sudo su -c "echo \"$line\" >> /etc/crontab"
# Restart cron service
sudo service cron restart && sudo systemctl restart cron

#=================================================
# RASPBERRY PI AS ROUTER

while true; do
echo ""
read -p "Will this machine act as a router? (y/n) " router
case $router in
[Yy]* ) echo "yes"; break;;
[Nn]* ) echo "no"; break;;
* ) echo "Please answer y or n.";;
esac
done

if [[ "$router" == "y" || "$router" == "Y" ]]; then
echo ""
# Install packages for 'router' operation and debugging
sudo apt install nmap dnsmasq iptables iptables-persistent -y

# Input 'router' subnet address
echo ""
echo "Your Raspberry Pi will manage local network (ethernet) route 192.168.xxx.0/24"
echo "with subnet xxx being between the value 2-254"
echo "and different with other Raspberry Pi routers in ZeroTier network"
read -p "Type in the value of subnet xxx: " subnet

# Run route.bash to configure routing operation
sudo bash /home/$(logname)/simhat_code/route.bash $subnet

# Write RaspberyPi's subnet-dependent command in dial.bash
sudo su -c "sed -i '/.*exit.*/d' /home/$(logname)/simhat_code/dial.bash"
echo -e "
# Count the number of hosts in a subnet (RasPi-as-Router LAN's network)
host_count=0
for host in {1..254}; do
host_ip=\"192.168.$subnet.\$host\"
if ! arp -n \$host_ip | grep -q \"no entry\"; then
host_count=\$((host_count+1))
fi
done
echo \"\"
# Run route.bash if no hosts are up (RasPi-as-Router LAN's network)
if ! [ \$host_count -gt 1 ]; then
echo \"NO ROUTING FUNCTION\"
sudo bash /home/$(logname)/simhat_code/route.bash $subnet
fi
exit 0" | sudo tee -a /home/$(logname)/simhat_code/dial.bash &> /dev/null

echo ""
echo "=========================================================="
echo "Installation of Raspberry Pi Router system is finished"
echo "The LAN's default gateway is 192.168.$subnet.1"
echo "with Subnet Mask 255.255.255.0"
echo "and DNS Server 8.8.8.8 (Google)"
echo "for up to 20 devices"

elif [[ "$router" == "n" || "$router" == "N" ]]; then
echo ""
echo "=========================================================="
echo "Installation of SIMHAT system is finished"
fi

echo ""
echo "Please reboot the RaspberryPi"
echo "=========================================================="
echo ""
exit 0