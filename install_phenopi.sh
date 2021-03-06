#!/bin/bash

# PhenoPi installation script!
# Installs necessary packages with minimal
# user intervention.

# create ramdisk for image stream
ramdisk=`cat /etc/fstab | grep data | wc -l`
if [[ ramdisk != "1" ]];then
	sudo mkdir /var/tmp
	echo "tmpfs /var/tmp tmpfs nodev,nosuid,size=10M 0 0" | sudo tee -a /etc/fstab
	sudo mount -a
fi

# enable the x server
xserver=`grep "start_x=1" /boot/config.txt | wc -l`

# no led light
led=`grep "disable_camera_led=1" /boot/config.txt | wc -l`

# enable xserver
## I skipped this step
if [ "$xserver" == "1" ]; then

## Continued here
	sudo sed -i "s/start_x=0/start_x=1/g" /boot/config.txt
fi

# enable camera if not enabled
# turn of red led light
if [ "$led" == "0" ]; then
	sudo echo "disable_camera_led=1" >> /boot/config.txt
fi

# read command line parameters
if [ -n "$1" ]; then
	echo $1 > /home/pi/phenopi/config.txt
else
	echo "default" > /home/pi/phenopi/config.txt
fi

if [ -n "$2" ]; then
	echo $2 >> /home/pi/phenopi/config.txt
else
 	echo 0 >> /home/pi/phenopi/config.txt
fi

# first test the connection to the google name server
connection=`ping -q -W 1 -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

# If the connection is down, bail
if [[ $connection != "ok" ]];then
	echo "No internet connection, can't determine time zone!"
	echo "Please connect to the net first."
	exit 1
else

	# some feedback
	echo "We are online"
	echo "-- looking up time zone"

	# update apt library
	sudo apt-get update

	# install geoip python library
	# install pip 
	# does not work "easy_install pip"
	sudo apt install python-pip
	#sudo easy_install pip > /dev/null 2>&1 # install pip
	
	# install the maxmind geoip database / backend
	sudo pip install python-geoip
	sudo pip install python-geoip-geolite2
	chmod +x ~/phenopi/mygeoip.py
	
	# determine the pi's external ip address
	current_ip=$(curl -s ifconfig.co)

	# get geolocation data 
	geolocation_data=$(~/phenopi/./mygeoip.py ${current_ip})

	# look up the location based upon the external ip
	latitude=$(echo ${geolocation_data} | awk '{print $1}')
	longitude=$(echo ${geolocation_data} | awk '{print $2}')

	# check if we have an internet connection
	timezone_data=$(curl -s http://new.earthtools.org/timezone/$latitude/$longitude)

	# grab the timezone offset from UTC (non daylight savings correction)
	time_offset=$(echo ${timezone_data} | grep -o -P -i "(?<=<offset>).*(?=</offset>)")

	# feedback
	echo "setting the time zone for: GMT${time_offset}"

	# grab the sign of the time_offset
	sign=`echo $time_offset | cut -c'1'`

	# swap the sign of the offset to 
	# convert the sign from the UTC time zone TZ variable (for plotting in overlay)
	if [ "$sign" == "-" ]; then
		tzone=`echo "$time_offset" | sed 's/-/+/g'`
	else
		tzone=`echo "-$time_offset"`
	fi

	# set the time zone, time will be set by the NTP server
	# if online
	sudo ln -sf /usr/share/zoneinfo/Etc/GMT$tzone /etc/localtime

	# feedback
	echo "installing the necessary software"
	echo "-- this might take a while, go get coffee"

	# install all packages we need
	### did not work error 
	###E: Could not get lock /var/cache/apt/archives/lock - open (11: Resource temporarily unavailable)
	### fix error
	
	sudo mv /var/cache/apt/archives/lock /var/cache/apt/archives/lock_bak
	###sudo apt-get -y install imagemagick > /dev/null 2>&1 # image manipulation software
	sudo apt install -y imagekick
	
	sudo apt-get -y install exif > /dev/null 2>&1 # install exif library 
	sudo apt-get -y install xrdp > /dev/null 2>&1 # remote graphical login
	sudo apt-get -y install lftp > /dev/null 2>&1 # ftp program with rsync qualities


	# install all dhcp necessary software
	# to create a wifi access point for wireless install
	sudo apt-get -y install hostapd > /dev/null 2>&1
	
	## has error Aug 08 00:06:15 raspberrypi systemd[1]: isc-dhcp-server.service: Control process exited, code=exited status=1
###aspberrypi systemd[1]: Failed to start LSB: DHCP server.
	sudo apt-get -y install isc-dhcp-server > /dev/null 2>&1 

##fix error?
        sudo apt-get -y install isc-dhcp-server-ldap	

	# move new access point server in place
	# this allows the use of 'rogue' wifi cards with the
	# realtek driver / chipset
	sudo mv -f /usr/sbin/hostapd /usr/sbin/hostapd.bak
	
	##does not work 
	sudo mv -f hostapd /usr/sbin
	## Fix download hostapd and scp into place scp /Users/saycel/Downloads/hostapd pi@192.168.1.74:/home/pi/phenopi/
	sudo mv -f hostapd /usr/sbin
	
	
###currently here
	
	sudo chmod 755 /usr/sbin/hostapd

	# dhcp settings
	##does not work 
	sudo mv -f isc-dhcp-server /etc/default/isc-dhcp-server
	### fix create file isc-dhcp-server and copy contents
	sudo mv -f isc-dhcp-server /etc/default/isc-dhcp-server
	
	
	
	### does not work - Error: Not searching LDAP since ldap-server, ldap-port and ldap-base-dn were not specified in the config file
	### Starting ISC DHCPv4 server: dhcpdcheck syslog for diagnostics. ... failed!
	### Failed to start LSB: DHCP server.
	sudo service isc-dhcp-server restart
		
	
###STUCK HERE
####pi@raspberrypi:/etc/ldap $ sudo service isc-dhcp-server restart
###Job for isc-dhcp-server.service failed because the control process exited with error code.
###See "systemctl status isc-dhcp-server.service" and "journalctl -xe" for details.

	  
	sudo mv -f dhcpd.conf /etc/dhcp/dhcpd.conf 
	sudo service dhcpd restart

	# feedback
	echo "installing the mjpeg streamer software"
	echo "-- give it some time"

	# install mjpeg streamer
	/home/pi/phenopi/./install_mjpeg_daemon.sh

	# feedback
	echo "configuring the system"

	crontab /home/pi/phenopi/crontab.txt
	
	# feedback
	echo "Done, rebooting the system"

	# reboot
	#sudo reboot
fi

# exit
exit 0 
