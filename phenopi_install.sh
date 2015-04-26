#!/bin/bash

# PhenoPi installation script!
# Installs necessary packages with minimal
# user intervention.

# Install necessary packages using default raspberry pi password!
# Please change the default password after the installation.

# update the system
echo 'raspberry' | sudo -Sk apt-get -y update
echo 'raspberry' | sudo -Sk apt-get -y upgrade
echo 'raspberry' | sudo -Sk apt-get -y clean

# install all packages
echo 'raspberry' | sudo -Sk apt-get -y install imagemagick # image manipulation software
echo 'raspberry' | sudo -Sk apt-get -y install exif # install exif library 
echo 'raspberry' | sudo -Sk apt-get -y install xrdp # remote graphical login

# copy the new index.html to the default web server directory
sudo mv index.html /var/www/

# set crontab file
init script on startup

# exit
exit 0 