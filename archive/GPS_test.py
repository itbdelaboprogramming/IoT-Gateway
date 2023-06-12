#!/usr/bin/python
# -*- coding:utf-8 -*-

import serial
import time
import os

path = os.path.dirname(os.path.abspath(__file__))
port = os.popen('bash {}/get_usb.bash'.format(path)).read().strip()
ser = serial.Serial(port,115200,timeout=3)
rec_buff = ''

def gps_decode(rec_buff):
	gps_data = str(rec_buff.decode())[13:]
	#
	Lat = gps_data[:2]
	SmallLat = gps_data[2:11]
	NorthOrSouth = gps_data[12]
	Long = gps_data[14:17]
	SmallLong = gps_data[17:26]
	EastOrWest = gps_data[27]
	#
	FinalLat = float(Lat) + (float(SmallLat)/60)
	FinalLong = float(Long) + (float(SmallLong)/60)
	if NorthOrSouth == 'S': FinalLat = -FinalLat
	if EastOrWest == 'W': FinalLong = -FinalLong
	print(FinalLat, FinalLong)

def send_at(command,back,timeout):
	rec_buff = ''
	ser.write((command+'\r\n').encode())
	time.sleep(timeout)
	if ser.inWaiting():
		time.sleep(0.01)
		rec_buff = ser.read(ser.inWaiting())
	if rec_buff != '':
		if back not in rec_buff.decode():
			print(command + ' ERROR')
			print(command + ' back:\t' + rec_buff.decode())
			return 0
		else:
			#print(rec_buff.decode())
			gps_decode(rec_buff)
			return 1
	else:
		print('GPS is not ready')
		return 0

def get_gps_position():
	ser.flushInput()
	rec_null = True
	answer = 0
	print('Start GPS session...')
	rec_buff = ''
	send_at('AT+CGPS=1,1','OK',1)
	#send_at('AT+CGPS=0','OK',1)
	#send_at('AT+CGPS=1','OK',1)
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


#Additions to Demo GPS.py Code Added by Tim // Simplfing the GPS Start up process
try:
	get_gps_position()

except :
	ser.close()

