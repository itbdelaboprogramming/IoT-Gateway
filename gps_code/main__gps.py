"""
#title           :main__gps.py
#description     :modbus Communication between YASKAWA D1000, YASKAWA GA500, Kyuden Battery 72 kWh, and Raspberry Pi + RS485/CAN Hat + USB-o-RS232C Adaptor
#author          :Nicholas Putra Rihandoko
#date            :2023/05/08
#version         :0.1
#usage           :Energy Monitoring System, RS-485 and RS-232C interface
#notes           :
#python_version  :3.7.3
#==============================================================================
"""

# Import library
import debug
import datetime # RTC Real Time Clock
import time
import socketio
import json
import simhat_gps

sio_server = "http://localhost:3000"
com_delay = 1
update_delay = 1

# Monitor Modbus communication for debugging
#debug.debugging()
cpu_temp = None     # RaspberryPi temperature for hardware fault monitoring
init = [True,True]  # variable to check modbus & mysql initialization

# Checking the GPS connection
while init[0]:
    try:
        gps = simhat_gps.node()
        print("<===== Connected to GPS =====>")
        print("")
        init[0] = False

    except BaseException as e:
        # Print the error message
        print("problem with GPS initialization:")
        print(e)
        print("<===== ===== retrying ===== =====>")
        print("")
        time.sleep(3)

# Checking the SocketIO connection
while init[1]:
    try:
        # Setup Raspberry Pi as Database client
        sio = socketio.Client()
        sio.connect(sio_server)
        print("<===== Connected to SocketIO Server =====>")
        print("")
        init[1] = False

    except BaseException as e:
        # Print the error message
        print("problem with SocketIO Server:")
        print(e)
        print("<===== ===== retrying ===== =====>")
        print("")
        time.sleep(3)

first = [True, True]
# Reading a Modbus message and Upload to database sequence
while not init[0] and not init[1]:
    try:
        # First run (start-up) sequence
        if first[0]:
            first[0] = False
            # time counter
            start = datetime.datetime.now()
            # Reset accumulated values for first time measurements
            
        # Send the command to read the measured value
        try:
            gps.get_position()
        except BaseException as e:
                # Print the error message
                print("problem with GPS :")
                print(e)
                print("<===== ===== continuing ===== =====>")
                print("")

        # Save and print the data
        timer = datetime.datetime.now()
        cpu_temp = debug.get_cpu_temperature()
        
        # Check elapsed time
        if (timer - start).total_seconds() > update_delay or first[1] == True:
            start = timer
            first[1] = False
            # Update/push data to database
            gps_data = {"id" : 1, "latitude" : gps.Latitude, "longitude" : gps.Longitude}
            gps2json = json.dumps(gps_data)
            print(gps2json)
            sio.emit("location",gps2json)
        
        time.sleep(com_delay)
    
    except BaseException as e:
        # Print the error message
        print("problem with -->",e)
        print("<===== ===== retrying ===== =====>")
        print("")
        time.sleep(1)