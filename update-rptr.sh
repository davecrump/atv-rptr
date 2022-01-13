#!/bin/bash

# Updated by davecrump 20220101 for the BATC ATV Repeater

DisplayUpdateMsg() {
  # Delete any old update message image
  rm /home/pi/tmp/update.jpg >/dev/null 2>/dev/null

  # Create the update image in the tempfs folder
  convert -size 800x480 xc:white \
    -gravity North -pointsize 40 -annotate 0 "\nUpdating Repeater Software" \
    -gravity Center -pointsize 50 -annotate 0 "$1""\n\nPlease wait" \
    -gravity South -pointsize 50 -annotate 0 "DO NOT TURN POWER OFF" \
    /home/pi/tmp/update.jpg

  # Display the update message on the desktop
  sudo fbi -T 1 -noverbose -a /home/pi/tmp/update.jpg >/dev/null 2>/dev/null
  (sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work
}

DisplayRebootMsg() {
  # Delete any old update message image  201802040
  rm /home/pi/tmp/update.jpg >/dev/null 2>/dev/null

  # Create the update image in the tempfs folder
  convert -size 800x480 xc:white \
    -gravity North -pointsize 40 -annotate 0 "\nUpdating Repeater Software" \
    -gravity Center -pointsize 50 -annotate 0 "$1""\n\nDone" \
    -gravity South -pointsize 50 -annotate 0 "SAFE TO POWER OFF" \
    /home/pi/tmp/update.jpg

  # Display the update message on the desktop
  sudo fbi -T 1 -noverbose -a /home/pi/tmp/update.jpg >/dev/null 2>/dev/null
  (sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work
}

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

reset

printf "\nCommencing update.\n\n"

cd /home/pi

## Check which update to load
GIT_SRC="BritishAmateurTelevisionClub"

if [ "$1" == "-d" ]; then
  echo "Overriding to update to latest development version"
  GIT_SRC="davecrump"
fi

if [ "$GIT_SRC" == "BritishAmateurTelevisionClub" ]; then
  echo "Updating to latest Production Bullseye BATC ATV Repeater RPi 4 build";
elif [ "$GIT_SRC" == "davecrump" ]; then
  echo "Updating to latest development Bullseye BATC ATV Repeater RPi 4 build";
else
  echo "Updating to latest ${GIT_SRC} Custom Bullseye BATC ATV Repeater RPi 4 build";
fi

printf "Pausing Repeater Controller if running.\n\n"
# sudo killall keyedstream >/dev/null 2>/dev/null

DisplayUpdateMsg "Step 3 of 10\nSaving Current Config\n\nXXX-------"

PATHCONFIG="/home/pi/atv-rptr/config"
PATHUBACKUP="/home/pi/user_backups"
CONFIGFILE="/home/pi/atv-rptr/config/repeater_config.txt"

# Note previous version number
cp -f -r /home/pi/atv-rptr/config/installed_version.txt /home/pi/atv-rptr/config/prev_installed_version.txt

# Remove previous User Config Backups
rm -rf "$PATHUBACKUP"

# Create a folder for user configs
mkdir "$PATHUBACKUP" >/dev/null 2>/dev/null

# Make a safe copy of repeater_config.txt
cp -f -r "CONFIGFILE" "$PATHUBACKUP"/repeater_config.txt

# Make a safe copy of Version Info
cp -f -r "$PATHCONFIG"/prev_installed_version.txt "$PATHUBACKUP"/prev_installed_version.txt


DisplayUpdateMsg "Step 4 of 10\nUpdating Software Package List\n\nXXXX------"

sudo dpkg --configure -a                            # Make sure that all the packages are properly configured
sudo apt-get clean                                  # Clean up the old archived packages
sudo apt-get update --allow-releaseinfo-change      # Update the package list

DisplayUpdateMsg "Step 5 of 10\nUpdating Software Packages\n\nXXXX------"

# --------- Update Packages ------

sudo apt-get -y dist-upgrade # Upgrade all the installed packages to their latest version

# --------- Install new packages as Required ---------


# ---------- Update atv-rptr -----------

DisplayUpdateMsg "Step 6 of 10\nDownloading Repeater SW\n\nXXXXX-----"

echo
echo "------------------------------------------"
echo "----- Updating the Repeater Software -----"
echo "------------------------------------------"

cd /home/pi

# Delete previous update folder if downloaded in error
rm -rf atv-rptr-main >/dev/null 2>/dev/null

# Download selected source of atv-rptr
wget https://github.com/${GIT_SRC}/atv-rptr/archive/main.zip -O main.zip

# Unzip and overwrite where we need to
unzip -o main.zip
rm -rf atv-rptr
mv atv-rptr-main/ atv-rptr
rm main.zip
cd /home/pi

DisplayUpdateMsg "Step 7 of 10\nCompiling Repeater SW\n\nXXXXXX----"

# Compile atv-rptr
#sudo killall -9 rpidatvgui
#echo "Installing rpidatvgui"
#cd /home/pi/rpidatv/src/gui
#make clean
#make
#sudo make install
cd /home/pi


DisplayUpdateMsg "Step 8 of 10\nRestoring Config\n\nXXXXXXXX--"

# Restore repeater_config.txt
cp -f -r "$PATHUBACKUP"/repeater_config.txt "$PATHCONFIG"/repeater_config.txt

# Restore version info
#cp -f -r "$PATHUBACKUP"/prev_installed_version.txt "$PATHCONFIG"/prev_installed_version.txt


DisplayUpdateMsg "Step 9 of 10\nFinishing Off\n\nXXXXXXXXX-"

# Update the version number

cp /home/pi/atv-rptr/latest_version.txt "$PATHCONFIG"/installed_version.txt

# Save (overwrite) the git source used
echo "${GIT_SRC}" > /home/pi/atv-rptr/config/${GIT_SRC_FILE}

# Reboot
DisplayRebootMsg "Step 10 of 10\nRebooting\n\nUpdate Complete"
printf "\nRebooting\n"

sleep 1
# Turn off swap to prevent reboot hang
sudo swapoff -a
sudo shutdown -r now  # Seems to be more reliable than reboot

exit
