#! /bin/bash

# Compile and run the repeater software

# set -x

CONFIGFILE="/home/pi/atv-rptr/config/repeater_config.txt"

############ Function to Read from Config File ###############

get_config_var() {
lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
local val = line:match("^#?%s*"..key.."=(.*)$")
if (val ~= nil) then
print(val)
break
end
end
EOF
}

pkill run-audio.sh  >/dev/null 2>/dev/null

sudo killall -9 fbi >/dev/null 2>/dev/null

sudo killall rptr >/dev/null 2>/dev/null

cd /home/pi/atv-rptr/src/rptr
touch main.c

make
if [ $? != "0" ]; then
  echo
  echo "failed install"
  cd /home/pi
  exit
fi

sudo make install

cd /home/pi
reset



# Put up the Start-up Splash Screen, which will be killed by the repeater process
sudo fbi -T 1 -noverbose -a /home/pi/atv-rptr/media/starting_up.jpg >/dev/null 2>/dev/null

# Source the script to build the default captions

source /home/pi/atv-rptr/scripts/build_captions.sh

MODE_STARTUP=$(get_config_var onboot $CONFIGFILE)


# Start a low level pink noise to maintain audio channel active
/home/pi/atv-rptr/scripts/run-audio.sh &


# Select the appropriate action

case "$MODE_STARTUP" in
  nil)
    # Go straight to command prompt
    exit
  ;;
  repeat)
    /home/pi/atv-rptr/bin/rptr
    exit
  ;;
  beacon)
    /home/pi/atv-rptr/bin/rptr
    exit
  ;;
  txoff)
    /home/pi/atv-rptr/bin/rptr
    exit
  ;;
  status)
    /home/pi/atv-rptr/bin/rptr
    exit
  ;;
  *)
    exit
  ;;
esac




