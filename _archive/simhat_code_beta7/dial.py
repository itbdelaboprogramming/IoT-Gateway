"""
#title           :dial.py
#description     :AT command configuration script, used through dial.bash file
#author          :Nicholas Putra Rihandoko
#date            :2023/04/25
#version         :3.1
#usage           :Iot Gateway
#notes           :take a look at README.txt for further info
#python_version  :3.7.3
#==============================================================================
"""
#!/usr/bin/python
# -*- coding:utf-8 -*-

# Import library
import sys
import os
import time
import serial

# Connect through serial communication to the SIM Card
path = os.path.dirname(os.path.abspath(__file__))
port = os.popen('bash {}/get_usb.bash'.format(path)).read().strip()
sim = serial.Serial(port, baudrate=115200, timeout=3)

# send AT command through serial communication, then read and print the response (expect)
def send_at(command,expect,wait):
    rec_buff = ''.encode()
    sim.write((command + '\r\n').encode())
    time.sleep(wait)
    if sim.inWaiting():
        rec_buff = sim.read(sim.inWaiting())
    if expect not in rec_buff.decode():
        print('command ' + command + ' failed')
        print('unexpected response:\t' + rec_buff.decode())
        return 0
    else:
        print(rec_buff.decode())
        return 1

if sys.argv[1] == "config":
    # Reset SIM Card configuration to default settings
    send_at('AT+CUSBPIDSWITCH=9001,1,1','OK',1)
    
    # Disable UART communication to let other modules use it
    send_at('AT+CCUART=0','OK',1)
    
    # Setup APN for IPv4 network on configuration no. 1
    send_at('AT+CGDCONT=1,"IP","{}"'.format(sys.argv[2]),'OK',1)
    
    if len(sys.argv)>3:
        # Setup username and password for network on configuration no. 1 using CHAP/PAP authentication (no. 3)
        send_at('AT+CGAUTH=1,3,"{}","{}"'.format(sys.argv[4],sys.argv[3]),'OK',1)
        
    # Activate network on configuration no. 1 using CHAP/PAP authentication (no. 3)
    send_at('AT+CGACT=1,3','OK',1)
    
else:
    # Remove the other wwan SIM card driver
    os.system('sudo su -c "rmmod qmi_wwan && rmmod simcom_wwan && rmmod simcom_wwan.ko &> /dev/null"')
    
    # Run make files to compile SIM Hat driver
    os.system('sudo su -c "cd {}/SIM7600_NDIS && make clean && make"'.format(path))
    
    # Install the Simcom SIM card driver (it will be automatically removed during every reboot)
    os.system('sudo su -c "cd {}/SIM7600_NDIS && insmod simcom_wwan.ko &> /dev/null"'.format(path))
    
    # Enable mobile data connection interface
    os.system('sudo ifconfig wwan0 up && sudo ip link set up wwan0')
    
    # Run AT command in dial.txt through minicom to setup start Internet Data Call
    send_at('AT$QCRMCALL=1,1','OK',2)
    
    # Obtain public address to connect to the internet
    os.system('sudo udhcpc -i wwan0')
    
    # Fix DNS error if happened
    os.system('sudo route add -net 0.0.0.0 wwan0 &> /dev/null')

sim.close()