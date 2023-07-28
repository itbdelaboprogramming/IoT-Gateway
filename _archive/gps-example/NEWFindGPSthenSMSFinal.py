#!/usr/bin/python
# -*- coding:utf-8 -*-
import RPi.GPIO as GPIO

import serial
import time

ser = serial.Serial('/dev/ttyS0',115200)
ser.flushInput()

power_key = 6
rec_buff = ''
time_count = 0

phone_number = 'Your Number Here'
text_message = ''

#Important User-Defined function to make talking to the HAT easier
def power_on(power_key):
	print('SIM7600X is starting:')
	GPIO.setmode(GPIO.BCM)
	GPIO.setwarnings(False)
	GPIO.setup(power_key,GPIO.OUT)
	time.sleep(0.1)
	GPIO.output(power_key,GPIO.HIGH)
	time.sleep(2)
	GPIO.output(power_key,GPIO.LOW)
	time.sleep(20)
	ser.flushInput()
	print('SIM7600X is ready')

def power_down(power_key):
	print('SIM7600X is loging off:')
	GPIO.output(power_key,GPIO.HIGH)
	time.sleep(3)
	GPIO.output(power_key,GPIO.LOW)
	time.sleep(18)
	print('Good bye')
	
def SendShortMessage(phone_number,text_message):
	
	print("Setting SMS mode...")
	send_at2("AT+CMGF=1","OK",1)
	print("Sending Short Message")
	answer = send_at2("AT+CMGS=\""+phone_number+"\"",">",2)
	#power_down(power_key)
	if 1 == answer:
		ser.write(text_message.encode())
		ser.write(b'\x1A')
		answer = send_at('','OK',20)
		if 1 == answer:
			print('send successfully')
		else:
			print('error')
	else:
		print('error%d'%answer)
	#power_down(power_key)

def send_at2(command,back,timeout):
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
		print(rec_buff.decode())
		return 1

def send_at(command,back,timeout):
	rec_buff = ''
	ser.write((command+'\r\n').encode())
	time.sleep(timeout)
	if ser.inWaiting():
		time.sleep(0.01 )
		rec_buff = ser.read(ser.inWaiting())
	if rec_buff != '':
		if back not in rec_buff.decode():
			print(command + ' ERROR')
			print(command + ' back:\t' + rec_buff.decode())
			return 0
		else:
			
			
			#print(rec_buff.decode())
			
			# Additions to Demo Code Written by Tim!
            global GPSDATA
            #print(GPSDATA)
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

            FinalLongText = round(FinalLong, 6)
            FinalLatText = round(FinalLat, 6)

            StringFinalLongText = str(FinalLongText)
            StringFinalLatText = str(FinalLatText)

            #print(FinalLat, FinalLong)

            #print(FinalLat, FinalLong)
            #print(rec_buff.decode())

            global text_message
            #text_message = ('Longitude is ' + ((float(Cleaned[1:8])/1000)) + ' S, and Latitude is '+((float(Cleaned[16:27]/1000)) + 'E'))
            text_message = ('The Raspberry Pi - Longitude is ' + StringFinalLongText + ' Degrees, and Latitude is ' + StringFinalLatText + ' Degrees')
            print(text_message)
            SendShortMessage(phone_number,text_message)
			
			
			
			
			#break
			return 1
	else:
		print('GPS is not ready')
		return 0


#Code Body Starts which utillises all the above Definitions
power_on(power_key)

rec_null = True
answer = 0
print('Start GPS session...')
rec_buff = ''
send_at('AT+CGPS=1,1','OK',1)
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
	time.sleep(1.5)


