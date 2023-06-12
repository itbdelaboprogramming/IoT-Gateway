import os
import pyudev
import psutil
import time

# Specify the filename
file_name = 'key.txt'

def check_key_file(device):
    # Check if the device is a USB drive
    if device.get('ID_BUS') == 'usb':
        usb_path = device.get('DEVNAME')
        print(usb_path)

        # Get the mount point of the USB drive
        partitions = psutil.disk_partitions(all=True)
        for partition in partitions:
            if 'removable' in partition.opts:
                mount_point = partition.mountpoint
                print(mount_point)

        # Check if the file exists
        file_path = os.path.join(mount_point, file_name)
        print(file_path)
        if os.path.isfile(file_path):
            with open(file_path, 'r') as file:
                # Read the contents of the file
                content = file.read().strip()
                print(content)
                
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
        print("USB drive not connected")

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
