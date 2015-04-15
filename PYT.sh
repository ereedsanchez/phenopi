#!/usr/bin/expect

# read parameters
set ip_address [lindex $argv 0]; # Grab the first command line parameter
set sitename [lindex $argv 1]; # Grab the first command line parameter
set privacy [lindex $argv 2]; # Grab the first command line parameter

# login to the pi using the default password
# run the install script
spawn ssh pi@${ip_address}
expect "?*assword"
send "raspberry\r"

# download the install files
expect "pi@"
send "wget https://bitbucket.org/khufkens/phenopi/get/phenopi.tar.gz\r"

# unzip install files
expect "pi@"
send "tar -xvf phenopi.tar.gz\r"

expect "pi@"
send "./phenopi_install.sh ${sitename} ${privacy}\r"

expect "pi@"
send "./real_time_clock_install.sh\r"

expect "pi@"
send "exit\r"
expect eof