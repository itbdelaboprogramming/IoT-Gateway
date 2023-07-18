"""
#title           :main__gps.py
#description     :
#author          :Nicholas Putra Rihandoko
#date            :2023/05/08
#version         :0.1
#usage           :
#notes           :
#python_version  :3.7.3
#==============================================================================
"""

# Import library
import datetime
import time
import query
#from lib import SIM7600_GNSS as gnss
from lib import SE100_GNSS as gnss
import socketio
import json

# Define MySQL Database parameters
mysql_server    = {"host":"10.4.171.204",
                    "user":"pi",
                    "password":"raspberrypi",
                    "db":"test",
                    "table":"diff_gps",
                    "port":3306}
mysql_timeout   = 3 # the maximum time this device will wait for completing MySQl query (in seconds)
mysql_interval = 60 # Seconds, used to maintain table row size
interval = 1    # Seconds
error_delay = 3 # Seconds
db_row_limit = 50

# Define SocketIO  parameters
sio_server = "http://localhost:3000"
sio_payload = {"id": 0,
                "data": {
                    "latitude": 33.2108277,
                    "longitude": 130.0459166,
                    "status": "GPS Not Ready",
                    "vehicle-name": "Base Station"
                }}

# Monitor Modbus communication for debugging
#debug.debugging()
init = True  # variable to check modbus & mysql initialization
sio = socketio.Client()

@sio.event
def connect():
    sio.emit("init","Connection Established")
    print("Connection Established")

@sio.event
def disconnect():
    print("Disconnected")

# Checking the GPS connection
while init:
    try:
        gps = gnss.node(sio_payload["data"]["vehicle-name"])
        #sio.connect(sio_server)
        print("<===== GPS Initialized =====>")
        print("")
        init = False

    except Exception as e:
        # Print the error message
        print(e)
        print("<===== ===== retrying ===== =====>")
        print("")
        time.sleep(3)

start = datetime.datetime.now()
# Reading a Modbus message and Upload to database sequence
while not init:          
    # Send the command to read the measured value
    gps.read_gps()
    timer = datetime.datetime.now()

    # Define MySQL queries and data which will be used in the program
    title = ["rtc","lat","lon","diff_lat","diff_lon","num_sats","hdop"]
    update_query = ("INSERT INTO `{}` ({}) VALUES ({})".format(mysql_server["table"],
                                                                ",".join(title),
                                                                ",".join(['%s' for _ in range(len(title))])))
    data = [gps.RTC.strftime("%H:%M:%S"), gps.Latitude, gps.Longitude,
            sio_payload["data"]["latitude"] - gps.Latitude, sio_payload["data"]["longitude"] - gps.Longitude,
            gps.Count_Satellites, gps.HDOP]
    query.print_response([gps],datetime.datetime.now())
    query.connect_mysql(mysql_server,update_query,data,mysql_timeout)

    # Send to the Socket.IO server
    try:
        sio_payload["data"]["latitude"] = gps.Latitude
        sio_payload["data"]["longitude"] = gps.Longitude
        sio_payload["data"]["status"] = gps.Status
        #sio.emit("gps",json.dumps(sio_payload))

        # REF = 33.2108277, 130.0459166
        gpsloc = {"latitude" : gps.Latitude, "longitude" : gps.Longitude}
        gpshead = {"heading" : 300}
        #sio.emit("location",json.dumps(gpsloc))
        #sio.emit("heading",json.dumps(gpshead))
    except Exception as e:
        # Handle incoming events or perform other operations
        print(f'Error connecting to Socket.IO server: {e}')
        time.sleep(error_delay)

    # Maintain table row size so that it is not too big
    if (timer - start).total_seconds() > mysql_interval:
        start = timer
        query.limit_db_rows(mysql_server,db_row_limit,mysql_timeout)

    time.sleep(interval)