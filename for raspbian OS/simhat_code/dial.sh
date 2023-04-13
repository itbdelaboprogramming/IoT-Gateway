#!/bin/sh

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
sudo minicom -D /dev/ttyUSB2 -S /home/$(logname)/simhat_code/dial.txt
sleep 1
# Obtain public address to connect to the internet
sudo udhcpc -i wwan0
sleep 1
# fix DNS error if happened
sudo route add -net 0.0.0.0 wwan0
sleep 1
exit