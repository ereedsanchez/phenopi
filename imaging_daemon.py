#!/usr/bin/python

from datetime import datetime
from subprocess import call, check_output
from time import sleep

# set the image acquisition interval
# fixed at a half hourly rate
interval=[0,30]
  
# check if we have a real time clock (RTC)
# i2c device (only check the bus 1 - newer pi s) 	
rtc=check_output("sudo i2cdetect -y 1 | grep UU | wc -l",shell=True)

# test the connection to the google name server
connection=check_output("ping -q -W 1 -c 1 8.8.8.8 > /dev/null && echo ok || echo error",shell=True)

# if we have a connection to the net and there is a hwclock
# update the hwclock. The internet connection is necessary to
# update the software clock using an NTP server. If there is
# no network this makes not sense
if rtc == "1" and connection == "ok" :
	call("sudo hwclock -w")


# create infinite imaging loop!
# if it's not time to take an image to upload
# update the image stream for the mjpg streamer
# webpage at /tmp/stream/pic.jpg
while true:

	# grap current time
	currentMinute = datetime.now().minute
	currentHour = datetime.now().hour

	# routine to grab gpio status and time the duration of the pulse

	if any(s == currentMinute for s in interval) and currentMinute and currentHour < 22 and currentHour > 4 :
	
		# upload a phenopi image
		call("/home/pi/phenopi/./upload_image.sh")
		
		# wait a minute, otherwise we duplicate uploads
		sleep(60)
	else
		# if no phenopi image is taken update the streaming
		# jpeg source
		call("raspistill -n -w 640 -h 480 -q 5 -o /tmp/stream/pic.jpg > /dev/null 2>&1")
	fi
