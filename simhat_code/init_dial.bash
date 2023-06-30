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
echo "Starting SIM Hat System installation..."
echo ""
echo "Press 'ctrl + C' to cancel"

while true; do
echo ""
read -p "Will this machine act as a Router? (Y/n) " yn_router
case $yn_router in
[Yy]*)
while true; do
echo ""
read -p "Do you want to configure the SIM card first? (Y/n): " yn_skip
case $yn_skip in
[Yy]*)
echo ""
echo "OK"
break;;
[Nn]*)
echo ""
echo "OK"
break;;
*)
echo ""
echo "Invalid input. Please answer 'y' or 'n'.";;
esac
done
break;;

[Nn]*)
echo ""
echo "OK"
yn_skip="n"
break;;
*)
echo ""
echo "Invalid input. Please answer 'y' or 'n'.";;
esac
done

# Enable execute (run program) privilege for all related files
sudo chmod +x /home/$(logname)/simhat_code/dial.bash
sudo chmod +x /home/$(logname)/simhat_code/dial.py
sudo chmod +x /home/$(logname)/simhat_code/route.bash
sudo chmod +x /etc/crontab

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

# Create cron command to check connection every 2 minutes, stars dial.bash if there is no internet
line='*/2 * * * * root sudo bash /home/$(logname)/simhat_code/dial.bash >> /home/$(logname)/simhat_code/dial.log 2>&1'
# Check whether the command line already exists in /etc/crontab, add or uncomment it if it does not
sudo su -c "sed -i '/.*simhat_code.*/d' /etc/crontab"
sudo su -c "echo \"$line\" >> /etc/crontab"
# Restart cron service
sudo service cron restart

# --------- this is the start of SIM Card config IF CONDITIONAL
if [[ "$yn_skip" == "y" || "$yn_skip" == "Y" ]]; then
echo "Continuing with SIM Card configuration..."
echo ""
echo "Please input the SIM card's APN information"
echo "Press 'Enter' for empty Username or Password"
echo ""
read -p "SIM Card APN: " sim_apn
read -p "SIM Card Username: " sim_user
read -p "SIM Card Password: " sim_pass
echo ""

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
sudo systemctl enable cron
# ssh and VNC for remote access
sudo systemctl enable ssh
sudo systemctl start ssh
sudo raspi-config nonint do_vnc 0

## Configure remote access
# Join the ZeroTier network
echo ""
echo "This machine needs to join ZeroTier network to enable remote access"
while true; do
read -p "Do you want to configure it now? (Y/n): " yn_zerotier
case $yn_zerotier in
[Yy]*)
while true; do
echo ""
read -p "Please input the ZeroTier Network_ID: " zt_net_id
sudo zerotier-cli join $zt_net_id
sleep 2
if sudo zerotier-cli listnetworks | grep -q "$zt_net_id"; then
break
else
echo ""
echo "Please try again."
fi
done

while true; do
read -p "Do you want this machine to join another ZeroTier network? (Y/n): " yn_zerotier
case $yn_zerotier in
[Yy]*)
while true; do
echo ""
read -p "Please input the ZeroTier Network_ID: " zt_net_id
sudo zerotier-cli join $zt_net_id
sleep 2
if sudo zerotier-cli listnetworks | grep -q "$zt_net_id"; then
break
else
echo ""
echo "Please try again."
fi
done;;
[Nn]*)
echo ""
echo "OK."
break;;
*)
echo ""
echo "Invalid input. Please answer 'y' or 'n'.";;
esac
done
break;;

[Nn]*)
echo ""
echo "OK."
break;;
*)
echo ""
echo "Invalid input. Please answer 'y' or 'n'.";;
esac
done
echo ""
echo "Continuing with SIM Card and internet configuration..."
echo ""

#=================================================
# CONNECTING TO THE INTERNET

## Configure SIM Card
# Run AT command in dial.py to setup SIM Card's APN
sudo python3 /home/$(logname)/simhat_code/dial.py config $sim_apn $sim_user $sim_pass

## Configure internet access
# Extract the zip file (.7z)
sudo su -c "cd /home/$(logname)/simhat_code && 7z x SIM7600_NDIS.7z   -r -o./SIM7600_NDIS -y"

# Run dial.py to initialize internet data call
lease=$(sudo python3 /home/$(logname)/simhat_code/dial.py lease | tail -1)
if [[ "$lease" == "ERROR" ]]; then
echo ""
echo "SIM Hat system installation incomplete"
echo "Exiting..."
echo ""
exit 0
fi

fi # --------- this is the end of SIM Card config IF CONDITIONAL

#=================================================
# RASPBERRY PI AS ROUTER

while true; do
case $yn_router in
[Yy]*)
echo ""
echo "Continuing with Router function configuration..."
echo ""
# Install packages for 'router' operation and debugging
sudo apt install dnsmasq iptables iptables-persistent tcpdump -y

# Input ZeroTier interface
while true; do
echo ""
echo "Here is your machine's ZeroTier network information:"
sudo zerotier-cli listnetworks
echo ""
echo "Type in the ZerotTier interface of the network that you want to route from the information above"
read -p " it should be in the format zt********* from the <dev> section: " zt_iface
if sudo zerotier-cli listnetworks | grep -q "$zt_iface"; then
echo ""
echo "OK"
break
else
echo ""
echo "Interface not found. Please try again."
fi
done

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
echo "Go to Members, search for this machine's ZeroTier address"
echo "On the \"Managed IPs\" column, add IP address: 172.21.$subnet.1"
break;;

[Nn]*) 
echo ""
echo "=========================================================="
echo "Installation of SIM Hat system (SIM Card configuration) is finished"
break;;

*)
echo "Invalid input. Please answer 'y' or 'n'.";;
esac
done

echo ""
echo "This machine's ZeroTier address is $(echo "$(sudo zerotier-cli info)" | awk '{print $3}')"
echo "Please authorize this machine in the ZeroTier Central network settings [my.zerotier.com]."
echo ""
echo "Also, please reboot the RaspberryPi, just in case :)"
echo "=========================================================="
echo ""
exit 0