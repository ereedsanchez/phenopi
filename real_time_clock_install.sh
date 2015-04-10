#!/bin/bash

# raspberry pi
# real time clock installation script
# run this script after the normal install routine
# as it reboots on success
# 
# requirements: an internet connection

# set default password
password="raspberry"

# first test the connection to the google name server
connection=`ping -q -W 1 -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

# If the connection is down, bail
if [[ $connection != "ok" ]];then
	exit 1
fi

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

# install all necessary packages
echo $password | sudo -Sk apt-get install i2c-tools
echo $password | sudo -Sk apt-get install package
echo $password | sudo -Sk apt-get install package

# check if we have a real time clock (RTC)
# i2c device (only check the bus 1 - newer pi s) 	
rtc_present=$(echo $password | sudo i2cdetect -y 1 | grep 68 | wc -l)

# If there is no RTC clock, set time zone
# offset and exit
if [[ ${rtc_present} == 0 ]];then
	exit 1
fi

# first we have to append some startup parameters
# and reboot

# So check if the boot config is up to date,
# if so continue to check if there is a RTC
# if not update boot parameters and reboot

# check boot config parameters
i2c=`grep "dtparam=i2c_arm=on" /boot/config.txt | wc -l`
rtc=`grep "dtoverlay=ds1307-rtc" /boot/config.txt | wc -l`

if [[ i2c == 0 & rtc == 0 ]]; then

		# append startup parameters to boot config
		echo $password | sudo -Sk cat >> /boot/config.txt <<EOL
		dtparam=i2c_arm=on
		dtoverlay=ds1307-rtc
EOL
	
		# reboot
		echo $password | sudo -Sk reboot
	
	else
	
		# continue with the install
		# and create the systemd parameter files
		echo $password | sudo -Sk cat >> somesystemd.file <<EOL
		[Unit]
		Description=Set time from RTC on startup
		After=network.target

		[Service]
		Type=oneshot
		ExecStart=/sbin/hwclock -s
		TimeoutSec=0

		[Install]
		WantedBy=multi-user.target
EOL
		echo $password | sudo -Sk cat >> somesystemd.file <<EOL
		[Unit]
		Description=Synchronise Hardware Clock to System Clock
		DefaultDependencies=no
		Before=shutdown.target

		[Service]
		Type=oneshot
		ExecStart=/sbin/hwclock --systohc

		[Install]
		WantedBy=reboot.target halt.target poweroff.target
EOL

		# do systems check
		echo $password | sudo -Sk systemctl enable hwclock-start hwclock-stop
	
		# change /lib/udev/hwclock-set replacing --systz with -hctosys
	
		# purge the fake hardware clock
		echo $password | sudo -Sk apt-get purge fake-hwclock
	
		# reboot the system, you should be set
		sudo -S reboot
		
fi














