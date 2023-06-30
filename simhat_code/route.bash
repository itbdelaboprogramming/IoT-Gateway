#!/bin/bash
#title           :route.bash
#description     :RPi as router configuration script, used through init_dial.bash file
#author          :Nicholas Putra Rihandoko
#date            :2023/06/12
#version         :1.1
#usage           :Iot Gateway
#notes           :
#==============================================================================

echo ""
ip_address="172.21.$2.1"
netmask="255.255.255.0"
rpi_man_route="172.21.$2.0/24"
dhcp_range_start=$(echo $ip_address | sed 's/\.[0-9]*$/\.2/')
dhcp_range_end=$(echo $ip_address | sed 's/\.[0-9]*$/\.21/')
dhcp_time="24h"
dns_server="8.8.8.8"
eth=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | grep -i eth)
wwan=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | grep -i wwan)
zt=$1

#=================================================
# IPTABLES SET UP

## Network routing configuration using iptables
# Allow IP packets to be forwarded
sudo echo 1 > /proc/sys/net/ipv4/ip_forward
# Also do this if it does not work:
#sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
#sudo sysctl -p /etc/sysctl.conf
# And/or do this:
sudo sysctl -w net.ipv4.ip_forward=1    # immediately enable, non persistent
# Start networking service
sudo systemctl start network-online.target
# Flush firewalls and reset rules to default (accept all)
sudo iptables -F
# Flush NAT table and reset port-forwarding and masquerading rules
sudo iptables -t nat -F

## NAT rules for port forwarding to/from the internet
# Set rules to match the source's address with wwan's address (masquerading) as the packet leaves network interface (postrouting chain) to internet
sudo iptables -t nat -A POSTROUTING -o $wwan -j MASQUERADE
# Allow forwarding of network traffic from wwan to eth and vice versa if the network traffic is part of existing connections or sessions
sudo iptables -A FORWARD -i $wwan -o $eth -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $eth -o $wwan -j ACCEPT

## NAT rules for port forwarding to/from the Zerotier virtual LAN
# Set rules to match the source's address with eth's address (masquerading) as the packet leaves network interface (postrouting chain) to ZeroTier virtual LAN
sudo iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE
# Allow forwarding of network traffic from eth to zt and vice versa if the network traffic is part of existing connections or sessions
sudo iptables -A FORWARD -i $eth -o $zt -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $zt -o $eth -j ACCEPT
# Allow traffic to and from TCP and UDP port 9993 for ZeroTier virtual LAN communication
sudo iptables -A INPUT -p udp --dport 9993 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 9993 -j ACCEPT
sudo iptables -A FORWARD -p udp --dport 9993 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 9993 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 9993 -j ACCEPT
sudo iptables -A FORWARD -p tcp --dport 9993 -j ACCEPT

# Save iptables rules for next boot using iptables-persistent
sudo su -c  "iptables-save > /etc/iptables/rules.v4"

#=================================================
# DNSMASQ SET UP

## DHCP & DNS settings for router operation using dnsmasq
# Set up static ip address fo Raspberry Pi on ethernet network
# Enable ethernet network interface
sudo ifconfig $eth down && sudo ip link set down $eth
sudo ifconfig $eth up && sudo ip link set up $eth
sudo ifconfig $eth $ip_address netmask $netmask
# Stop dnsmasq service
sudo systemctl stop dnsmasq
# Remove default route created by dhcpcd
sudo ip route del 0/0 dev $eth
sudo rm -rf /etc/dnsmasq.d/*
# Add new routing rules for dnsmasq
sudo echo -e "interface=$eth
bind-interfaces
server=$dns_server
domain-needed
bogus-priv
dhcp-range=$dhcp_range_start,$dhcp_range_end,$dhcp_time" > /tmp/custom-dnsmasq.conf
sudo cp /tmp/custom-dnsmasq.conf /etc/dnsmasq.d/custom-dnsmasq.conf
# Start dnsmasq service
sudo systemctl start dnsmasq