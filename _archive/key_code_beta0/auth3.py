import os
import pyudev
import time

# Specify the path to the USB drive and the filename
usb_path = '/media/pi/Nicholas'  # Replace 'USB_drive_name' with the actual name of your USB drive
file_name = 'key.txt'

def check_key_file(device):
    # Check if the device is a USB drive
    if os.path.exists(usb_path):
        file_path = os.path.join(usb_path, file_name)

        # Check if the file exists
        if os.path.isfile(file_path):
            with open(file_path, 'r') as file:
                # Read the contents of the file
                content = file.read().strip()

            # Check if the keyword 'yes' is present
            if 'yes' in content:
                # Run the python script
                os.system('python3 /home/pi/run.py')
                print("Success")
            else:
                print("No key")
        else:
            print("File not found")
    else:
        print("USB key not connected")

# Create a context for monitoring
context = pyudev.Context()

# Create a monitor to watch for USB events
monitor = pyudev.Monitor.from_netlink(context)
monitor.filter_by(subsystem='block', device_type='disk')

# Monitor for USB drive events
for action, device in monitor:
    if action == 'add':
        time.sleep(1)
        check_key_file(device)
