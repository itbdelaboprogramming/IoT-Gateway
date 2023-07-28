## untuk cek id dari serial device yg lagi dicolok, lakuin command ini di terminal
ls -l /dev/serial/by-id

## misalnya nanti dapet ini
lrwxrwxrwx 1 root root 13 Jul 22 15:38 usb-la86_USB2.0-Serial-if00-port0 -> ../../ttyUSB0
lrwxrwxrwx 1 root root 13 Jul 22 15:38 usb-Prolific_Technology_Inc._USB-Serial_Controller --> ../../ttyUSB1

## catet id device yg dibutuhkan (ga harus semua, sebagian aja juga gpp asalkan beda dengan device yg lain)
## di python pakai command ini untuk dapet directory nya, contohnya
import os
port_id = 'usb-la86_USB2.0'
path = 'director/tempat/script/get_usb/disimpan'
port = os.popen('sudo bash {}/get_usb.bash {}'.format(path, port_id)).read().strip()

## nanti hasilnya adalah port = '/dev/ttyUSB0'
kalau script get_usb.path nya ditaruh di directory yg sama dengan main program, bisa pakai ini
path = os.path.dirname(os.path.abspath(__file__))

## kalau pakai pakai port directory langsung juga bisa (misal port_id = "/dev/ttyUSB2")
## di dalam script get_usb juga sudah ditambah command untuk tambah root privilage