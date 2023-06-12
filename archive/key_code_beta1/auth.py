"""
#title           :auth.py
#description     :IoT key feature main script, used through init_auth.bash file
#author          :Nicholas Putra Rihandoko
#date            :2023/04/25
#version         :3.1
#usage           :Iot Gateway
#notes           :take a look at README.txt for further info
#python_version  :3.7.3
#==============================================================================
"""

import os
import sys
import time
import pyudev
import psutil
import subprocess
from cryptography.fernet import Fernet

# Specify the path to the USB drive and the filename
usb_path = '/media/pi/Nicholas'  # Replace 'USB_drive_name' with the actual name of your USB drive
code_path = os.path.dirname(os.path.abspath(__file__))
iot_key_name = 'iot_key.txt'
encryptor_name = 'encryptor.txt'
keyword_name = 'keyword.txt'
script1=['/home/pi/modbus_code','main.py']

# Specify the relevant directory path
class path:
    def __init__(self):
        global usb_path, code_path, iot_key_name, encryptor_name, keyword_name
        self.encryptor_path = os.path.join(code_path, encryptor_name)
        self.keyword_path = os.path.join(code_path, keyword_name)
        self.iot_key_path = os.path.join(code_path, iot_key_name)
        self.file_path = os.path.join(usb_path, iot_key_name)
# Get the directory path of the script
dir = path()

def encrypt_file(file_path, key):
    # Read the contents of the file
    with open(file_path, 'rb') as file:
        data = file.read()

    # Encrypt the contents using the given key
    f = Fernet(key)
    encrypted_data = f.encrypt(data)

    # Write the encrypted contents back to the file
    with open(file_path, 'wb') as file:
        file.write(encrypted_data)

def decrypt_file(file_path, key):
    # Read the encrypted contents of the file
    with open(file_path, 'rb') as file:
        encrypted_data = file.read()

    # Decrypt the contents using the given key
    f = Fernet(key)
    decrypted_data = f.decrypt(encrypted_data)

    # Write the decrypted contents back to the file
    with open(file_path, 'wb') as file:
        file.write(decrypted_data)

def create_key(iot_keyword):
    global dir
    create_new = [True, True]
    # Check existing encryptor file
    if os.path.isfile(dir.encryptor_path) and os.path.getsize(dir.encryptor_path) > 0:
        print("Encryption key already exist in", dir.encryptor_path)
        user_input = input('Do you want to overwrite it? (y/n): ').lower()
        if user_input == 'n':
            create_new[0] = False
            # Read the encryption key file
            with open(dir.encryptor_path, 'rb') as file:
                key = file.read().strip()
    if create_new[0]:
        # Create the text file and write the encryption key to it
        key = Fernet.generate_key().decode()
        with open(dir.encryptor_path, 'w') as file:
            file.write(key)
        print("New encryption key created & saved in", dir.encryptor_path)
    
    print("")
    
    # Check existing keyword file
    if os.path.isfile(dir.keyword_path) and os.path.getsize(dir.keyword_path) > 0:
        print("Keyword already exist in", dir.keyword_path)
        user_input = input('Do you want to overwrite it? (y/n): ').lower()
        if user_input == 'n':
            create_new[1] = False
            # Read the keyword file
            with open(dir.keyword_path, 'rb') as file:
                iot_keyword = file.read().decode()
    if create_new[1]:
        # Create the text file and write the keyword to it
        with open(dir.keyword_path, 'w') as file:
            file.write(iot_keyword)
        print("New keyword created & saved in", dir.keyword_path)
    
    # Create the text file for encrypted keyword
    with open(dir.iot_key_path, 'w') as file:
        file.write(iot_keyword)
    encrypt_file(dir.iot_key_path, key)

    # Copy the encrypted keyword file to USB key 
    os.system('sudo yes | cp -rf {} {} &> /dev/null'.format(dir.iot_key_path, dir.file_path))
    print("")
    
def iot_start(script):
    global dir, usb_path
    # Obtain the encyption key from the code's directory
    with open(dir.encryptor_path, 'r') as file:
        key = file.read().strip()

    # Check if the USB drive is connected
    if os.path.exists(usb_path):

        # Check if the file exists
        if os.path.isfile(dir.file_path):
            # Decrypt the contents of the file
            decrypt_file(dir.file_path, key)
            
            # Read the contents of the file
            with open(dir.file_path, 'r') as file:
                content = file.read().strip()

            # Read the contents of the file
            with open(dir.keyword_path, 'r') as file:
                keyword = file.read().strip()
            
            # Check if the keyword is present and correct
            if content == keyword:
                # Run the python script
                os.system('python3 {}/{} &'.format(script[0],script[1]))
                print("Successful authentication: IoT script is now running")
            else:
                print("Failed authentication: wrong keyword")
            
            # Encrypt the contents of the file
            encrypt_file(dir.file_path, key)
        else:
            print("Failed authentication: keyfile not found")
    else:
        print("USB key not connected")
    print("")

def iot_stop(script):
    global usb_path
    print("")
    # Check if the USB drive is not connected
    if not os.path.exists(usb_path):
        # Find the process ID (PID) of the python script
        pid = None
        for process in psutil.process_iter(['pid', 'name']):
            if process.info['name'] == 'python3' and script[1] in ' '.join(process.cmdline()):
                pid = process.info['pid']
                break

        # If the process ID (PID) was found, terminate the process
        if pid:
            subprocess.run(['kill', str(pid)])
            print("Successfully terminated the IoT script.")
        else:
            print("The IoT script is not currently running.")
    else:
        print("USB key is still connected")
    print("")

if sys.argv[1] == "monitor":
    # Create a context for monitoring
    context = pyudev.Context()

    # Create a monitor to watch for USB events
    monitor = pyudev.Monitor.from_netlink(context)
    monitor.filter_by(subsystem='block', device_type='disk')

    # Monitor for USB drive events
    print("USB key monitoring service is now running ...")
    print("")
    for action, device in monitor:
        time.sleep(3)
        if action == 'add':
            iot_start(script1)
        if action == 'remove':
            iot_stop(script1)
        print("USB key monitoring service is now running ...")
        print("")

elif sys.argv[1] == "generate":
    new_key = create_key(sys.argv[2])
    
elif sys.argv[1] == "decrypt":
    with open(dir.encryptor_path, 'r') as file:
        key = file.read().strip()
    decrypt_file(dir.iot_key_path, key)
    
elif sys.argv[1] == "terminate":
    iot_stop(script1)