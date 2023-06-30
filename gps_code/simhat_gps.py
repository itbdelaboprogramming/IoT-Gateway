"""
#title           :simhat_gps.py
#description     :Main script to obtain GPS data
#author          :Nicholas Putra Rihandoko
#date            :2023/06/21
#version         :0.2
#usage           :Iot Gateway
#notes           :take a look at README.txt for further info
#python_version  :3.7.3
#==============================================================================
"""

#!/usr/bin/python
# -*- coding:utf-8 -*-

import serial
import time
import os

class node:
    def __init__(self):
        # Intialize variables
        self.Latitude = None
        self.Longitude = None
        self.status = "GPS Not Ready"

        # Configure serial communication for AT Command
        path = os.path.dirname(os.path.abspath(__file__))
        port = os.popen('bash {}/get_usb.bash'.format(path)).read().strip()
        self._ser = serial.Serial(port,115200,timeout=3)
        self._ser.flushInput()
        print('Start GPS session...')

        # Enable SIM Hat's GNSS feature
        #self.send_at('AT+CGPS=0','OK',1)
        #time.sleep(2)
        self.send_at('AT+CGPS=1','OK',1)
        time.sleep(2)

    def gps_decode(self,data):
        # Determine GPS' status based on the AT command response
        if ',,,,,,' not in data:
            self.status = "GPS Position Locked"
            gps_data = str(data)[25:-9].split(',')
            
            # Calculate Latitude and Longitude
            Lat = round(float(gps_data[0][:-9])+(float(gps_data[0][-9:])/60),8)
            Long = round(float(gps_data[2][:-9])+(float(gps_data[2][-9:])/60),8)
            if gps_data[1] == 'N': self.Latitude = Lat
            else: self.Latitude = -Lat
            if gps_data[3] == 'E': self.Longitude = Long
            else: self.Longitude = -Long
        else:
            self.status = "GPS Signal Lost"

    def send_at(self,command,back,timeout):
        # Send AT Commands to SIM Hat module using serial communication
        rec_buff = ''
        self._ser.write((command+'\r\n').encode())
        time.sleep(timeout)
        # Read AT Command's responses
        if self._ser.inWaiting():
            time.sleep(1)
            rec_buff = self._ser.read(self._ser.inWaiting())
        if rec_buff != '':
            if back not in rec_buff.decode():
                print(command + ' ERROR')
                print('back: ' + rec_buff.decode() + '\n')
                return 0
            else:
                data = rec_buff.decode()
                print(data)
                # Decode GNSS information into readable format
                if command == "AT+CGPSINFO": self.gps_decode(data)
                return 1
        else:
            return 0

    def get_position(self):
        # Get GNSS infomation from SIM Hat module
        answer = self.send_at('AT+CGPSINFO','+CGPSINFO: ',1)
        if 1 == answer:
            answer = 0
            time.sleep(1)
        else:
            self.status = "GPS not ready"

    def shutdown(self):
        # Disable GPS then close serial communication
        self.send_at('AT+CGPS=0','OK',1)
        self._ser.close()