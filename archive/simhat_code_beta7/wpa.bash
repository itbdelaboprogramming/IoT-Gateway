sudo apt install dhcpcd hostapd dnsmasq iptables bridge-utils

# Pass all traffic between wlan0 and eth0 interfaces
sudo brctl addbr br0
sudo brctl addif br0 eth0

sudo nano /etc/network/interfaces
auto br0
#iface br0 inet manual
bridge_ports eth0 wlan0


# Configure Wi-Fi as access point
sudo nano /etc/hostapd/hostapd.conf
interface=wlan0
bridge=br0
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
ssid=RASPI4N
wpa_passphrase=raspberrypi4n

sudo nano /etc/default/hostapd
#vhange #DAEMON_CONF="" to
DAEMON_CONF="/etc/hostapd/hostapd.conf"


# Configure a Static IP for the Wlan0 Interface
sudo nano /etc/dhcpcd.conf
interface wlan0
static ip_address=192.168.100.1/23
#denyinterfaces eth0
#denyinterfaces wlan0
nohook wpa_supplicant
sudo systemctl restart dhcpcd