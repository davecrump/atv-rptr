#!/bin/bash

# set -x

# This script is sourced from .bashrc at boot and ssh session start
# to sort out driver issues and
# to select the user's selected start-up option.
# Dave Crump 20220102

############ Set Environment Variables ###############

PATHSCRIPT=/home/pi/atv-rptr/scripts
PATHRPI=/home/pi/atv-rptr/bin
PATHCONFIGS="/home/pi/atv-rptr/config"  ## Path to config files
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

############ Function to Write to Config File ###############

set_config_var() {
lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
if line:match("^#?%s*"..key.."=.*$") then
line=key.."="..value
made_change=true
end
print(line)
end
if not made_change then
print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}

######################### Start here #####################

if [ "$SESSION_TYPE" == "cron" ]; then
  SESSION_TYPE="boot"
else
  # Determine if this is a user ssh session, or an autoboot
  case $(ps -o comm= -p $PPID) in
    sshd|*/sshd)
      SESSION_TYPE="ssh"
    ;;
    login|sudo)
      SESSION_TYPE="boot"
    ;;
    *)
      SESSION_TYPE="ssh"
    ;;
  esac
fi

# If repeater is already running and this is an ssh session
# stop the gui, start the menu and return
#ps -cax | grep 'rptr' >/dev/null 2>/dev/null
#RESULT="$?"
#if [ "$RESULT" -eq 0 ]; then
#  if [ "$SESSION_TYPE" == "ssh" ]; then
#    killall rpidatvgui >/dev/null 2>/dev/null
#    killall siggen >/dev/null 2>/dev/null
#    /home/pi/rpidatv/scripts/menu.sh menu
#  fi
#  return
#fi

# So continue assuming that this could be a first-start
# or it could be a second ssh session.

# Read the desired start-up behaviour
MODE_STARTUP=$(get_config_var onboot $CONFIGFILE)

# If pi-sdn is not running, check if it is required to run
ps -cax | grep 'pi-sdn' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -ne 0 ]; then
  if [ -f /home/pi/.pi-sdn ]; then
    . /home/pi/.pi-sdn
  fi
fi

# Put up the Start-up Splash Screen, which will be killed by the repeater process
sudo fbi -T 1 -noverbose -a /home/pi/atv-rptr/media/starting_up.jpg >/dev/null 2>/dev/null
#(sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work

# Source the script to build the default captions
source /home/pi/atv-rptr/scripts/build_captions.sh

/home/pi/atv-rptr/scripts/run-audio.sh &

# Select the appropriate action

case "$MODE_STARTUP" in
  nil)
    # Go straight to command prompt
    return
  ;;
#  Console)
#    # Start the menu if this is an ssh session
#    if [ "$SESSION_TYPE" == "ssh" ]; then
#      /home/pi/rpidatv/scripts/menu.sh menu
#    fi
#    return
#  ;;
  repeat)
    /home/pi/atv-rptr/bin/rptr
    return
  ;;
  beacon)
    /home/pi/atv-rptr/bin/rptr
    return
  ;;
  txoff)
    /home/pi/atv-rptr/bin/rptr
    return
  ;;
  status)
    /home/pi/atv-rptr/bin/rptr
    return
  ;;
  *)
    return
  ;;
esac


