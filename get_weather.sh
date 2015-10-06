#!/bin/bash
 
function get_weather() {

	# first test the connection to a google dns server
	connection=`ping -q -W 1 -c 1 8.8.8.8 > /dev/null && echo ok || echo error`

	#if the connection is up, proceed
	if [[ $connection == "ok" ]];then

		# determine the pi's external ip address
		current_ip=$(curl -s ifconfig.me)

		# get geolocation data 
		geolocation_data=$(./geoip.py ${current_ip})

		# look up the location based upon the external ip
		latitude=$(echo ${geolocation_data} | awk '{print $1}')
		longitude=$(echo ${geolocation_data} | awk '{print $2}')

		# get the current weather for the current location
		# for some reason I can't split the lines, keep as is
		current_weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/forecast/daily?lat=${latitude}&lon=${longitude}&cnt=1&mode=json&units=metric")

		# extract parameters from openweathermap.org station summary

		temp_day=$(echo $current_weather_data |\
		 sed 's/:/ /g' | grep -oP -i '(?<="day"\s)[^\,]*')

		temp_min=$(echo $current_weather_data |\
		 sed 's/:/ /g' | grep -oP -i '(?<="min"\s)[^\,]*')

		temp_max=$(echo $current_weather_data |\
		 sed 's/:/ /g' | grep -oP -i '(?<="max"\s)[^\,]*')

		humidity=$(echo $current_weather_data |\
		 sed 's/:/ /g' | grep -oP -i '(?<="humidity"\s)[^\,]*')

		visibility=$(echo $current_weather_data |\
		 sed 's/:/ /g' | grep -oP -i '(?<="description"\s)[^\,]*' | sed 's/"//g')

		clouds=$(echo $current_weather_data |\
		 sed 's/:/ /g' | grep -oP -i '(?<="clouds"\s)[^\,]*' | sed 's/["{}]//g')

		wind_speed=$(echo $current_weather_data |\
		 sed 's/:/ /g' | grep -oP -i '(?<="speed"\s)[^\,]*')

		pressure=$(echo $current_weather_data |\
		 sed 's/:/ /g' | grep -oP -i '(?<="pressure"\s)[^\,]*')

		# create weather string, to be put in EXIF data
		weather_string=$(echo "IP: ${current_ip},\
		 Lat_deg: ${latitude},\
		 Long_deg: ${longitude},\
		 Temp_day_C: ${temp_day},\
		 Temp_min_C: ${temp_min},\
		 Temp_max_C: ${temp_max},\
		 Hum_%: ${humidity},\
		 Press_hPa: ${pressure},\
		 Wind_mps: ${wind_speed},\
		 Vis_char: ${visibility},\
		 Clouds_%: ${clouds}\
		 ")

		# return value
		echo $weather_string
	
	else
	
		# output empty string
		weather_string=$(echo "IP: NA,\
		 Lat_deg: NA,\
		 Long_deg: NA,\
		 Temp_day_C: NA,\
		 Temp_min_C: NA,\
		 Temp_max_C: NA,\
		 Hum_%: NA,\
		 Press_hPa: NA,\
		 Wind_mps: NA,\
		 Vis_char: NA,\
		 Clouds_%: NA\
		 ")
	
		# return value
		echo $weather_string
	fi
}
