#!/bin/bash
#title           :init_gps.bash
#description     :the server installation for for vehicle tracking using SocketIO and SIM HAT Nodule
#author          :Nicholas Putra Rihandoko
#date            :2023/06/21
#version         :2.1
#usage           :Modbus programming in Python
#notes           :
#==============================================================================

# Enable UART for communication with the RS485 Hat
sed -i 's/^enable_uart=0/enable_uart=1/g' /boot/config.txt
sed -i 's/^#enable_uart=0/enable_uart=1/' /boot/config.txt
sed -i 's/^#enable_uart=1/enable_uart=1/' /boot/config.txt
# If the previous lines does not exist yet, add it in /boot/config.txt
if ! sudo grep -q "enable_uart=1" /boot/config.txt; then
    sudo sed -i '4i enable_uart=1' /boot/config.txt
fi
# Use /dev/ttyAMA0 instead of /dev/ttyS0 to solve odd/even parity bit problem
if ! sudo grep -q "dtoverlay=disable-bt" /boot/config.txt; then
    sudo sed -i '4i dtoverlay=disable-bt' /boot/config.txt
fi
# Enable SPI
sudo raspi-config nonint do_spi 0
# Disable Serial Port to disable Serial Console, then enable Serial port without Serial Console
sudo raspi-config nonint do_serial 1
sudo raspi-config nonint do_serial 2
# Disable/comment bluetooth over serial port
sed -i 's/^dtoverlay=pi-minuart-bt/#&/g' /boot/config.txt

# Enable execute (run program) privilege for all related files
sudo chmod +x /home/$(logname)/gps_server_code/main__gps.py
sudo chmod +x /home/$(logname)/gps_server_code/gnss.py
sudo chmod +x /home/$(logname)/gps_server_code/dashboard_server/server.js
# Install pip for python library manager
sudo apt update
sudo apt install python3-pip
# Install the necessary python library
sudo pip3 install python-socketio
sudo pip3 install websocket-client
sudo pip3 install pymysql
# Install Node js, Express js, ans socket.io
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | sudo bash
source ~/.bashrc
nvm install 12.22.12
nvm alias default 12.22.12
sudo apt install npm -y
cd gps_server_code/dashboard_server
npm init -y
npm i socket.io@4.7.1 express@4.18.2 morgan@1.10.0 dotenv@16.3.1
npm audit fix
npm update engine.io ws

# Start GPS module configuration
while true; do
echo ""
echo "The GPS module needs to be configured"
echo "Available configuration:"
echo "1) SIM7600"
echo "2) SE100"
echo "3) ~ others"
echo ""
read -p "Input the number --> " gps_model
case $gps_model in
[1]*)
sudo python3 /home/$(logname)/gps_server_code/gnss.py SIM7600
sudo > /home/$(logname)/gps_server_code/lib/get_usb.bash
sudo cat <<endoffile >> /home/$(logname)/gps_server_code/lib/get_usb.bash
#!/bin/bash
# Find the line with specific USB name
line=\$(ls -l /dev/serial/by-id | grep 'SimTech__Incorporated_SimTech__Incorporated_0123456789ABCDEF-if02')
# Extract the device name from the line
path=\$(echo "\$line" | awk '{print \$NF}')
# Check if the device name was found
if [ -n "\$path" ]; then
filename=\$(basename "\$path")
device_name="\${filename%.*}"
echo "/dev/\$device_name"
else
echo ""
fi
endoffile
break;;

[2]*)
while true; do
echo ""
echo "Choose the SE100 communication media"
echo "Available configuration:"
echo "1) UART (Tx-Rx) pinout"
echo "2) USB-to-TTL"
echo "3) ~ others"
echo ""
read -p "Input the number --> " se100_com
case $se100_com in
[1]*)
sudo > /home/$(logname)/gps_server_code/lib/get_usb.bash
sudo cat <<endoffile >> /home/$(logname)/gps_server_code/lib/get_usb.bash
#!/bin/bash
echo "/dev/ttyAMA0"
endoffile
break;;
[2]*)
sudo > /home/$(logname)/gps_server_code/lib/get_usb.bash
sudo cat <<endoffile >> /home/$(logname)/gps_server_code/lib/get_usb.bash
#!/bin/bash
# Find the line with specific USB name
line=\$(ls -l /dev/serial/by-id | grep 'usb-Prolific_Technology_Inc._USB-Serial_Controller')
# Extract the device name from the line
path=\$(echo "\$line" | awk '{print \$NF}')
# Check if the device name was found
if [ -n "\$path" ]; then
filename=\$(basename "\$path")
device_name="\${filename%.*}"
echo "/dev/\$device_name"
else
echo ""
fi
endoffile
break;;
[3]*)
echo ""
echo "Please configure the GPS module by yourself"
break;;
*)
echo ""
echo "Invalid input. Please answer from the number on the list.";;
esac
done
break;;

[3]*)
echo ""
echo "Please configure the GPS module by yourself"
break;;

*)
echo ""
echo "Invalid input. Please answer from the number on the list.";;
esac
done

echo ""
echo "=========================================================="
echo ""
echo "Installation of GPS system is finished"
echo ""
echo "Please reboot the RaspberryPi, just in case :)"
echo ""
echo "=========================================================="
echo ""
exit 0