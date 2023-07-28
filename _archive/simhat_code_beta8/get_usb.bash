#!/bin/bash
#title           :get_usb.bash
#description     :Script to find the SIM Hat Module's USB directory
#author          :Nicholas Putra Rihandoko
#date            :2023/06/12
#version         :1.1
#usage           :IoT Gateway
#notes           :
#==============================================================================

# Find the line with specific USB name
line=$(ls -l /dev/serial/by-id | grep 'SimTech__Incorporated_SimTech__Incorporated_0123456789ABCDEF-if02')

# Extract the 'ttyUSB5' part from the line
path=$(echo "$line" | awk '{print $NF}')

# Check if the device name was found
if [ -n "$path" ]; then
filename=$(basename "$path")
device_name="${filename%.*}"
echo "/dev/$device_name"
else
echo ""
fi