#!/bin/bash

# infinite image acquisition deamon
# providing images to the phenopi
# server as well as the internal
# moving jpeg server at port 8080

# set the image acquisition interval
# fixed at a half hourly rate
interval=`seq 0 30 59`

# create infinite loop
# if it's not time to take an image to upload
# update the image stream for the mjpg streamer
# webpage at /tmp/stream/pic.jpg
while:
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
	raspistill -n -w 640 -h 480 -q 5 -o /tmp/stream/pic.jpg
fi
	
done