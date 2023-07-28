#!/usr/bin/python

import RPi.GPIO as GPIO
import serial
import time

GPIO.setwarnings(False) 
GPIO.setmode(GPIO.BCM)
GPIO.setup(21, GPIO.OUT)
GPIO.output(21, GPIO.LOW)


ser = serial.Serial("/dev/ttyS0",115200)
ser.flushInput()

phone_number = '' #********** change it to the phone number you want to call
text_message = ''
power_key = 6
rec_buff = ''


def send_at(command,back,timeout):
	rec_buff = ''
	ser.write((command+'\r\n').encode())
	time.sleep(timeout)
	
	if ser.inWaiting():
		time.sleep(0.01 )
		
		#print(rec_buff)
		rec_buff = ser.read(ser.inWaiting())
		#print(rec_buff)
	if rec_buff != '':
		print(rec_buff.decode())
		if 'red' in rec_buff.decode(): GPIO.output(21, GPIO.HIGH), time.sleep(3), GPIO.output(21, GPIO.LOW)
		if back not in rec_buff.decode():print(command + ' back:\t' + rec_buff.decode())
		return 0
	else:
		#print(rec_buff)
		global TEXTDATA
		TEXTDATA = str(rec_buff)
		print(TEXTDATA)
		return 1
	
	
def ReceiveShortMessage():
	rec_buff = ''
	#print('Setting SMS mode...')
	send_at('AT+CMGF=1','OK',1)
	send_at('AT+CMGL="REC UNREAD"', 'OK', 1)
	answer = send_at('AT+CMGL="REC UNREAD"', '+CMTI', 1)
	
	#A = ser.read(ser.inWaiting())
	#B = A.decode()
	#print(B)
	#buffer_string = str(rec_buff) + str(ser.read(ser.inWaiting()))
	#buffer_string2 = bytes(buffer_string)
	#buffer_string3 = buffer_string2.decode()
	#print(buffer_string3)
	
	#if 'n' in buffer_string:
	#	lines=buffer_string.split('n')
	#	last_received = lines[-2]   
	#A = ser.readline()
	#print(buffer_string)
	
	
	if 1 == answer:
		answer = 0
		#print(rec_buff)
		if 'red' in rec_buff:
			answer = 1
			print('Turning LEDS onto RED')
	else:
		print('No New text')
		return False
	return True
# 
# def ReceiveShortMessage():
# 	rec_buff = ''
# 	print('Setting SMS mode...')
# 	send_at('AT+CMGF=1','OK',1)
# 	send_at('AT+CMGL="REC UNREAD"', 'OK', 1)
# 	answer = str(send_at('AT+CMGL="REC UNREAD"', 'OK', 1))
# 	#answer = send_at('AT+CMGL="REC UNREAD"','+CMGR:',2)
# 	print(answer)
# 	if 1 == answer:
# 		answer = 0
# 		if 'OK' in rec_buff:
# 			answer = 1
# 			print(rec_buff + 'This is the Location')
# 	else:
# 		print('error%d'%answer)
# 		return False
# 	return True

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

power_on(power_key)
while True:
	
	ReceiveShortMessage()
