"""
#title           :jobs.py
#description     :IoT key's lists of script to be monitored
#author          :Nicholas Putra Rihandoko
#date            :2023/06/12
#version         :1.1
#usage           :Iot Gateway
#notes           :
#python_version  :3.7.3
#==============================================================================
"""

#!/usr/bin/python
# -*- coding:utf-8 -*-

import os
import sys
import psutil
import subprocess

# Specify the path to the USB drive and the filename
jobs_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),'jobs.txt')

def run():
    print("")
    # Find the process ID (PID) of the python script
    with open(jobs_path, 'rb') as file:
        for line in file:
            jobs = line.rstrip().decode().split(' ')
            pid = None
            for process in psutil.process_iter(['pid', 'name']):
                if process.info['name'] == jobs[0] and jobs[2] in ' '.join(process.cmdline()):
                    pid = process.info['pid']
                    print(process.info)
                    break
            # If the process ID (PID) was found, terminate the process
            if pid:
                print("The script is already running.")
            else:
                os.system('{} {}/{} &'.format(jobs[0],jobs[1],jobs[2]))
                print("Successfully run the script.")
                print("")

def kill():
    print("")
    # Find the process ID (PID) of the python script
    with open(jobs_path, 'rb') as file:
        for line in file:
            jobs = line.rstrip().decode().split(' ')
            pid = None
            for process in psutil.process_iter(['pid', 'name']):
                if process.info['name'] == jobs[0] and jobs[2] in ' '.join(process.cmdline()):
                    pid = process.info['pid']
                    break

             # If the process ID (PID) was found, terminate the process
            if pid:
                subprocess.run(['sudo', 'kill', str(pid)])
                print("Successfully kill the script.")
            else:
                print("The script is not running.")
                print("")

if sys.argv[1] == "run":
    run()
elif sys.argv[1] == "kill":
    kill()