#!/usr/bin/expect

# read parameters
ip_address=$1
sitename=$2
privacy=$3


# login to the pi using the default password
# run the install script
spawn ssh pi@${ip_address}
expect "?*assword"
send "raspberry\r"

# download the install files
#expect "pi@"
#send "wget https://myfile.com/test.tar.gz\r"

# unzip install files
expect "pi@"
send "tar xf test.tar.gz\r"

expect "pi@"
send "./phenopi_install.sh ${sitename} ${privacy}\r"

expect "pi@"
send "./real_time_clock_install.sh\r"

expect "pi@"
send "exit\r"
expect eof