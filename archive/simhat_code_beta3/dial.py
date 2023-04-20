import sys
import os
import time
import serial

sim = serial.Serial('/dev/ttyUSB2', baudrate=115200, timeout=1)

if sys.argv[1] == "init_dial":
    # Reset SIM Card configuration to default settings
    sim.write(b'AT+CUSBPIDSWITCH=9001,1,1\r\n')
    time.sleep(1)
    # Disable UART communication to let other modules use it
    sim.write(b'AT+CCUART=0\r\n')
    time.sleep(1)
    # Setup APN for IPv4 network on configuration no. 1
    sim.write('AT+CGDCONT=1,"IP","{}"\r\n'.format(sys.argv[2]).encode())
    time.sleep(1)
    if len(sys.argv)>3:
        # Setup username and password for network on configuration no. 1 using CHAP/PAP authentication (no. 3)
        sim.write('AT+CGAUTH=1,3,"{}","{}"\r\n'.format(sys.argv[4],sys.argv[3]).encode())
        time.sleep(1)
    # Activate network on configuration no. 1 using CHAP/PAP authentication (no. 3)
    sim.write(b'AT+CGACT=1,3\r\n')
    time.sleep(1)
else:   #in this instance, the sys.argv[1] should equal the $(logname) directory
    # Remove the other wwan SIM card driver
    os.system('sudo su -c "rmmod qmi_wwan && rmmod simcom_wwan && rmmod simcom_wwan.ko" &'.format(sys.argv[1]))
    time.sleep(1)
    # Run make files to compile SIM Hat driver
    os.system('sudo su -c "cd /home/{}/simhat_code/SIM7600_NDIS && make clean && make"'.format(sys.argv[1]))
    time.sleep(1)
    # Install the Simcom SIM card driver (it will be automatically removed during every reboot)
    os.system('sudo su -c "cd /home/{}/simhat_code/SIM7600_NDIS && insmod simcom_wwan.ko"'.format(sys.argv[1]))
    time.sleep(3)
    # Enable mobile data connection interface
    os.system('sudo ifconfig wwan0 up && sudo ip link set up wwan0')
    time.sleep(3)
    # Run AT command in dial.txt through minicom to setup start Internet Data Call
    sim.write(b'AT$QCRMCALL=1,1\r\n')
    time.sleep(1)
    # Obtain public address to connect to the internet
    os.system('sudo udhcpc -i wwan0')
    time.sleep(1)
    # Fix DNS error if happened
    os.system('sudo route add -net 0.0.0.0 wwan0')
    time.sleep(1)

sim.close()