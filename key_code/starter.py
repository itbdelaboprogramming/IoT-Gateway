"""
#title           :starter.py
#description     :IoT key feature scheduling script, used to start the main scripts on scheduled interval
#author          :Nicholas Putra Rihandoko
#date            :2023/06/21
#version         :1.2
#usage           :Iot Gateway
#notes           :
#python_version  :3.7.3
#==============================================================================
"""

#!/usr/bin/python
# -*- coding:utf-8 -*-

import os
import psutil

def starter():
    pid = None
    # Find the process ID (PID) of the python script
    for process in psutil.process_iter(['pid', 'name']):
        if process.info['name'] == 'python3' and 'auth.py' in ' '.join(process.cmdline()):
            pid = process.info['pid']
            break

    # If the process ID (PID) was found, terminate the process
    if pid:
        print(process.info)
        #os.system('sudo kill {}'.format(pid))
        pass
    else:
        # If not, excute the script
        os.system('python3 {}/{} start'.format(os.path.dirname(os.path.abspath(__file__)),'auth.py'))
        os.system('python3 {}/{} stop'.format(os.path.dirname(os.path.abspath(__file__)),'auth.py'))
        os.system('python3 {}/{} monitor &'.format(os.path.dirname(os.path.abspath(__file__)),'auth.py'))

        # If you want to skip the authentication process, comment the three lines above, then uncomment this line bellow
        #os.system('python3 {}/{} run'.format(os.path.dirname(os.path.abspath(__file__)),'src/jobs.py'))

        print("Successfully run the script.")
        print("")


starter()
# Run backup procedure, uncomment if needed
#os.system('python3 {}/{}'.format(os.path.dirname(os.path.abspath(__file__)),'backup.py'))
