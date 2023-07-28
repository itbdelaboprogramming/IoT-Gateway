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
from lib import SIM7600_GNSS as gnss
#from lib import SE100_GNSS as gnss
import socketio
import json
import os

# Define GPS port
port_id = 'SimTech__Incorporated_SimTech__Incorporated_0123456789ABCDEF-if02' # for SIM7600 GPS module
#port_id = 'usb-Prolific_Technology_Inc._USB-Serial_Controller' # for SE100 GPS module using USB-to-TTL adaptor
#port_id = '/dev/ttyAMA0' # for SE100 GPS module using RX-TX (UART) pinout
gps_port = os.popen('sudo bash {}/get_usb.bash {}'.format(os.path.dirname(os.path.abspath(__file__)), port_id)).read().strip()

# Define MySQL Database parameters
mysql_server    = {"host":"10.4.171.204",
                    "user":"pi",
                    "password":"raspberrypi",
                    "db":"test",
                    "table":"diff_gps",
                    "port":3306}
mysql_timeout   = 3 # the maximum time this device will wait for completing MySQl query (in seconds)
interval        = 1 # the period between each subsequent communication routine/loop (in seconds)

# NIW REF = 33.2108277, 130.0459166
# ITB REF = -6.889777, 107.608666
# Define SocketIO  parameters
sio_server = "http://10.4.171.54:3000"
sio_payload = {"id": 0,
                "data": {
                    "latitude": None,
                    "longitude": None,
                    "status": "GPS Not Ready",
                    "vehicle-name": "Car A"
                }}

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

# Calculate Differential GPS using MySQL
def dgps_correction(mysql_server,rtc,raw_gps,timeout=2):
    try:
        if rtc: mysql_query = ("SELECT diff_lat, diff_lon, num_sats, hdop, lat, lon FROM {} WHERE RTC = '{}' ORDER BY id DESC LIMIT 1".format(mysql_server["table"],rtc))
        else: mysql_query = ("SELECT diff_lat, diff_lon, num_sats, hdop, lat, lon FROM {} ORDER BY id DESC LIMIT 1".format(mysql_server["table"]))
        # Read the previous timestamps from database
        i = 1
        while True:
            base_station = query.connect_mysql(mysql_server,mysql_query,timeout=timeout)
            if base_station:
                # Change the format into suitable timedate objects
                for data in base_station:
                    new_latitude = round(raw_gps.Latitude + data[0],7)
                    new_longitude = round(raw_gps.Longitude + data[1],7)
                    diff_sats = raw_gps.Count_Satellites - data[2]
                    diff_hdop = round(raw_gps.HDOP - data[3],2)
                    ref_raw_lat = round(data[4],7)
                    ref_raw_lon = round(data[5],7)
                break
            else:
                print(" -- no RTC data, retrying -- ")
                if i == 3: break
                else:
                    time.sleep(1)
                    i+=1
        if base_station: return [new_latitude, new_longitude, diff_sats, diff_hdop, ref_raw_lat, ref_raw_lon]
        else:
            print(" << skipping RTC data >> ")
            print("")
            return ["","","","","",""]
    except: return ["","","","","",""]

# Checking the GPS connection
while init:
    try:
        gps = gnss.node(gps_port, sio_payload["data"]["vehicle-name"])
        sio.connect(sio_server)
        print("<===== GPS Initialized =====>")
        print("")
        init = False

    except Exception as e:
        # Print the error message
        print(e)
        print("<===== ===== retrying ===== =====>")
        print("")
        time.sleep(3)

# Main loop
while not init:
    try:       
        # Send the command to read the measured value
        timer = datetime.datetime.now()
        gps.read_gps()

        # Calculate differential correction
        latest_data = dgps_correction(mysql_server, None, gps)
        rtc_data = dgps_correction(mysql_server, gps.RTC.strftime("%H:%M:%S"), gps)

        # Save data to csv for analysis
        title = ["time","raw_lat","raw_lon","num_sats","hdop",
                    "latest_lat","latest_lon","latest_sats_diff","latest_hdop_diff",
                    "rtc_lat","rtc_lon","rtc_sats_diff","rtc_hdop_diff",
                    "ref_raw_lat_latest", "ref_raw_lon_latest", "ref_raw_lat_rtc","ref_raw_lon_rtc"]
        data = [timer.strftime("%Y-%m-%d %H:%M:%S"), gps.Latitude, gps.Longitude, gps.Count_Satellites, gps.HDOP,
                latest_data[0],latest_data[1],latest_data[2],latest_data[3],
                rtc_data[0],rtc_data[1],rtc_data[2],rtc_data[3],
                latest_data[4],latest_data[5],rtc_data[4],rtc_data[5]]
        query.log_in_csv(title, data, timer, 'gps_log.csv')
        query.print_response([gps],timer)
            
        # Send to the Socket.IO server
        try:
            #sio_payload["data"]["latitude"] = gps.Latitude
            #sio_payload["data"]["longitude"] = gps.Longitude
            #sio_payload["data"]["status"] = gps.Status
            #sio.emit("gps",json.dumps(sio_payload))

            # NIW REF = 33.2108277, 130.0459166
            # ITB REF = -6.889777, 107.608666
            gpsloc = {"latitude" : latest_data[0], "longitude" : latest_data[1]}
            gpshead = {"heading" : 300}
            sio.emit("location",json.dumps(gpsloc))
            sio.emit("heading",json.dumps(gpshead))
        except Exception as e:
            # Handle incoming events or perform other operations
            print(f'Error connecting to Socket.IO server: {e}')

        time.sleep(interval)

    except Exception as e:
        # Print the error message
        print(e)
        print("<===== ===== retrying ===== =====>")
        print("")
        time.sleep(3)
