#!/bin/bash

# PhenoPi installation script!
# Installs necessary packages with minimal
# user intervention.

# Install necessary packages using default raspberry pi password!
# Please change the default password after the installation.


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

	# determine the pi's external ip address
	current_ip=$(curl -s ifconfig.me)

	# get geolocation data 
	geolocation_data=$(curl -s http://freegeoip.net/xml/${current_ip})

	# look up the location based upon the external ip
	latitude=$(echo ${geolocation_data} | \
		grep -o -P -i "(?<=<Latitude>).*(?=</Latitude>)")
	
	longitude=$(echo ${geolocation_data} | \
		grep -o -P -i "(?<=<Longitude>).*(?=</Longitude>)")

	# check if we have an internet connection
	timezone_data=$(curl -s http://www.earthtools.org/timezone/$latitude/$longitude)

	# grab the timezone offset from UTC (non daylight savings correction)
	time_offset=$(echo ${timezone_data} | \
		grep -o -P -i "(?<=<offset>).*(?=</offset>)")

	# feedback
	echo "setting the time zone for: GMT${time_offset}

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

	# update the system
	sudo apt-get -y update
	sudo apt-get -y upgrade
	sudo apt-get -y clean

	# install all packages
	sudo apt-get -y install imagemagick # image manipulation software
	sudo apt-get -y install exif # install exif library 
	sudo apt-get -y install xrdp # remote graphical login

	# install mjpeg streamer
	./install_mjpeg_daemon.sh

	# copy the new index.html to the default web server directory
	sudo mv index.html /var/www/

	# set crontab file
	init script on startup

fi

# exit
exit 0 