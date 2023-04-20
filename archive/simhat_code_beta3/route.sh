#!/bin/bash

# Share Wifi with Eth device
#
#
# This script is created to work with Raspbian Stretch
# but it can be used with most of the distributions
# by making few changes.
#
# Make sure you have already installed `dnsmasq`
# Please modify the variables according to your need
# Don't forget to change the name of network interface
# Check them with `ifconfig`

ip_address="192.168.100.1"
netmask="255.255.255.0"
dhcp_range_start="192.168.100.2"
dhcp_range_end="192.168.100.20"
dhcp_time="24h"
dns_server="1.1.1.1"
eth="eth0"
wwan="wwan0"

# start networking service
sudo systemctl start network-online.target &> /dev/null

# flush firewalls and reset rules to default (accept all)
sudo iptables -F
# flush NAT table and reset port-forwarding and masquerading rules
sudo iptables -t nat -F
# set rules to match the source's address with wwan's address (masquerading) as the packet leaves network interface (postrouting chain) 
sudo iptables -t nat -A POSTROUTING -o $wwan -j MASQUERADE
# allow forwarding of network traffic from wwan to eth if the network traffic is part of existing connections or sessions
sudo iptables -A FORWARD -i $wwan -o $eth -m state --state RELATED,ESTABLISHED -j ACCEPT
# allow network traffic to pass from eth to wwan
sudo iptables -A FORWARD -i $eth -o $wwan -j ACCEPT

# allow IP packets to be forwarded
#sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
# also do this if it does not work:
#sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
#sudo sysctl -p /etc/sysctl.conf
# and/or this:
sudo sysctl -w net.ipv4.ip_forward=1    # immediately enable, non persistent

#set up static ip address fo raspberry pi on ethernet network
sudo ifconfig $eth down
sudo ifconfig $eth up
sudo ifconfig $eth $ip_address netmask $netmask

# Remove default route created by dhcpcd
sudo ip route del 0/0 dev $eth &> /dev/null
sudo systemctl stop dnsmasq
sudo rm -rf /etc/dnsmasq.d/* &> /dev/null

# add new routing rules and start dnsmasq
sudo echo -e "interface=$eth
bind-interfaces
server=$dns_server
domain-needed
bogus-priv
dhcp-range=$dhcp_range_start,$dhcp_range_end,$dhcp_time" > /tmp/custom-dnsmasq.conf

sudo cp /tmp/custom-dnsmasq.conf /etc/dnsmasq.d/custom-dnsmasq.conf
sudo systemctl start dnsmasq

# POERT FORWARDING
ZT_IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | grep -i zt)
#
sudo iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE
#
sudo iptables -A FORWARD -i $eth -o $ZT_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
#
sudo iptables -A FORWARD -i $ZT_IFACE -o $eth -j ACCEPT
#
sudo iptables -A INPUT -p udp --dport 9993 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 9993 -j ACCEPT
