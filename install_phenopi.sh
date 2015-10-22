#!/bin/bash

# PhenoPi installation script!
# Installs necessary packages with minimal
# user intervention.

# Install necessary packages using default raspberry pi password!
# Please change the default password after the installation.

# install geoip python library
sudo apt-get -y install python-setuptools python-dev build-essential > /dev/null 2>&1 # all necessary python tools (pip)

# install pip 
sudo apt-get -y install python-pip > /dev/null 2>&1 # install pip
chmod +x geoip.py
	
# install the maxmind geoip database / backend
pip install python-geoip
pip install python-geoip-geolite2
	
# enable the x server
xserver=`grep "start_x=1" /boot/config.txt | wc -l`

# no led light
led=`grep "disable_camera_led=1" /boot/config.txt | wc -l`

# enable xserver
if [$xserver == "1" ]; then
	sudo sed -i "s/start_x=0/start_x=1/g" /boot/config.txt
fi

# enable camera if not enabled
# turn of red led light
if [$led == "0" ]; then
	sudo echo "disable_camera_led=1" >> /boot/config.txt
fi

# read command line parameters
if [ -n "$1" ]; then
	echo $1 > /home/pi/phenopi/config.txt
else
	echo "default" > /home/pi/phenopi/config.txt
fi

if [ -n "$2" ]; then
	echo $1 >> /home/pi/phenopi/config.txt
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
	
	# determine the pi's external ip address
	current_ip=$(curl -s ifconfig.me)

	# get geolocation data 
	geolocation_data=$(./geoip.py ${current_ip})

	# look up the location based upon the external ip
	latitude=$(echo ${geolocation_data} | awk '{print $1}')
	longitude=$(echo ${geolocation_data} | awk '{print $2}')

	# check if we have an internet connection
	timezone_data=$(curl -s http://www.earthtools.org/timezone/$latitude/$longitude)

	# grab the timezone offset from UTC (non daylight savings correction)
	time_offset=$(echo ${timezone_data} | \
		grep -o -P -i "(?<=<offset>).*(?=</offset>)")

	# feedback
	echo "setting the time zone for: GMT${time_offset}"

	# grab the sign of the time_offset
	sign=`echo $time_offset | cut -c'1'`

	# swap the sign of the offset to 
	# convert the sign from the UTC time zone TZ variable (for plotting in overlay)
	if [ "$sign" == "+" ]; then
		tzone=`echo "$time_offset" | sed 's/+/-/g'`
	else
		tzone=`echo "$time_offset" | sed 's/-/+/g'`
	fi

	# set the time zone, time will be set by the NTP server
	# if online
	sudo ln -sf /usr/share/zoneinfo/Etc/GMT$tzone /etc/localtime

	# feedback
	echo "installing the necessary software"
	echo "-- this might take a while, go get coffee"

	# update the system
	sudo apt-get -y update > /dev/null 2>&1
	sudo apt-get -y upgrade > /dev/null 2>&1
	sudo apt-get -y clean > /dev/null 2>&1

	# install all packages we need
	sudo apt-get -y install imagemagick > /dev/null 2>&1 # image manipulation software
	sudo apt-get -y install exif > /dev/null 2>&1 # install exif library 
	sudo apt-get -y install xrdp > /dev/null 2>&1 # remote graphical login
	sudo apt-get -y install lftp > /dev/null 2>&1 # ftp program with rsync qualities

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
