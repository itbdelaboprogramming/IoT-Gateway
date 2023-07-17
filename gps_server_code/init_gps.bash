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

#start configuration
echo "Available configuration: SE100, SIM7600"
read -p "Input your GPS model --> " GPS
sudo python3 /home/$(logname)/gps_server_code/gnss.py $GPS

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