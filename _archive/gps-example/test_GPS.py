#!/usr/bin/python
# -*- coding:utf-8 -*-
import serial
import time
ser = serial.Serial("/dev/ttyUSB2",115200)
rec_buff = ''
def gps_decode(rec_buff):
#global GPSDATA
GPSDATA = str(rec_buff.decode())
Cleaned = GPSDATA[13:]

#print(Cleaned)

Lat = Cleaned[:2]
SmallLat = Cleaned[2:11]
NorthOrSouth = Cleaned[12]

#print(Lat, SmallLat, NorthOrSouth)

Long = Cleaned[14:17]
SmallLong = Cleaned[17:26]
EastOrWest = Cleaned[27]

#print(Long, SmallLong, EastOrWest)   
FinalLat = float(Lat) + (float(SmallLat)/60)
FinalLong = float(Long) + (float(SmallLong)/60)
			
if NorthOrSouth == 'S': FinalLat = -FinalLat
if EastOrWest == 'W': FinalLong = -FinalLong
print(FinalLat, FinalLong)

#print(FinalLat, FinalLong)
#print(rec_buff.decode())

def send_at(command,back,timeout):
rec_buff = ''
ser.write((command+'\r\n').encode())
time.sleep(timeout)
if ser.inWaiting():
time.sleep(0.01 )
rec_buff = ser.read(ser.inWaiting())
if back not in rec_buff.decode():
print(command + ' ERROR')
print(command + ' back:\t' + rec_buff.decode())
return 0
else:
#print(rec_buff.decode())
gps_decode(rec_buff)
return 1

def get_gps_position():
ser.flushInput()
rec_null = True
answer = 0
print('Start GPS session...')
rec_buff = ''
send_at('AT+CGPS=0','OK',1)
send_at('AT+CGPS=1','OK',1)
time.sleep(2)
while rec_null:

answer = send_at('AT+CGPSINFO','+CGPSINFO: ',1)
if 1 == answer:
answer = 0
if ',,,,,,' in rec_buff:
print('GPS is not ready')
rec_null = False
time.sleep(1)
else:
print('error %d'%answer)
rec_buff = ''
send_at('AT+CGPS=0','OK',1)
return False
time.sleep(1.5)

try:
get_gps_position()

except :
ser.close()



