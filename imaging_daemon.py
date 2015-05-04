#!/usr/bin/python

# load libraries
import RPi.GPIO as GPIO
from datetime import datetime
from subprocess import call, check_output
from time import sleep

# set gpio pins
GPIO.setmode(GPIO.BCM)
GPIO.setup(24, GPIO.IN, pull_up_down = GPIO.PUD_UP)

# setup a callback function to take a picture when
# the button is pressed
def startTime(channel):
        global sec
        # waiting for button release
        sec = 0
        while (GPIO.input(24) == GPIO.LOW):

                # delay for debouncing
                sleep(0.2)
                sec += 0.2

# intiate callback function
GPIO.add_event_detect(24, GPIO.FALLING, callback=test, bouncetime=300)

# set the image acquisition interval
# fixed at a half hourly rate
interval=[0,30]

# create infinite imaging loop!
# if it's not time to take an image to upload
# update the image stream for the mjpg streamer
# webpage at /tmp/stream/pic.jpg
while True:

        # grap current time
        currentMinute = datetime.now().minute
        currentHour = datetime.now().hour

        if sec >= 5:
		# shutdown (no gpio cleanup needed)
                call("sudo shutdown -h now",shell=True)

        elif sec > 0 and sec < 5:
                # take snapshot
                call("raspistill -o /home/pi/snapshot.jpg",shell=True)

        elif:
                if any(s == currentMinute for s in interval) and currentHour < 22 and currentHour > 4 :

                        # upload a phenopi image
                        call("/home/pi/phenopi/./upload_image.sh",shell=True)

                        # wait a minute, otherwise we duplicate uploads
                        sleep(60)
                else:
                        # if no phenopi image is taken update the streaming
                        # jpeg source
                        call("raspistill -n -w 640 -h 480 -q 95 -t 500 -th none -o /tmp/pic.jpg > /dev/nu$


# cleanup gpio pins
GPIO.cleanup()

