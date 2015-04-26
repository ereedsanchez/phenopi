#!/bin/bash

# infinite image acquisition deamon
# providing images to the phenopi
# server as well as the internal
# moving jpeg server at port 8080

# set the image acquisition interval
# fixed at a half hourly rate
interval=`seq 0 30 59`

# check if we have a real time clock (RTC)
# i2c device (only check the bus 1 - newer pi s) 	
rtc_present=$(sudo i2cdetect -y 1 | grep UU | wc -l)

# test the connection to the google name server
connection=`ping -q -W 1 -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

# if we have a connection to the net and there is a hwclock
# update the hwclock. The internet connection is necessary to
# update the software clock using an NTP server. If there is
# no network this makes not sense
if [[ ${rtc_present} == "1" && $connection == "ok" ]]; then
	sudo hwclock -w
fi

# create infinite imaging loop!
# if it's not time to take an image to upload
# update the image stream for the mjpg streamer
# webpage at /tmp/stream/pic.jpg
while true;
do

# grap current time
hour=`date | cut -d' ' -f4 | cut -d':' -f1`
minutes=`date | cut -d' ' -f4 | cut -d':' -f2`

if [[ $interval =~ $minutes && $hour < 22 && $hour > 4 ]]; then
	# upload a phenopi image
	~/bin/./upload_image.sh
	# wait a minute, otherwise we duplicate uploads
	sleep 60
else
	# if no phenopi image is taken update the streaming
	# jpeg source
	raspistill -n -w 640 -h 480 -q 5 -o /tmp/stream/pic.jpg > /dev/null 2>&1
fi
	
done