#!/bin/bash
#title           :get_usb.bash
#description     :Script to find the USB key's directory
#author          :Nicholas Putra Rihandoko
#date            :2023/06/12
#version         :1.1
#usage           :IoT Gateway
#notes           :
#==============================================================================

directory="/media/pi"

# Check if the directory is not empty
if [ "$(ls -A $directory)" ]; then
# Iterate over subdirectories
for subdirectory in "$directory"/*; do
# Check if iot_key.txt file exists in the subdirectory
if [ -f "$subdirectory/iot_key.txt" ]; then
echo "$subdirectory"
else
echo "$directory/devicenotfound"
fi
done
fi