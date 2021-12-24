#Get the last 6 digits of the WiFi MAC Address
MAC_SUFFIX=`ifconfig wlan0 | sed -n "/ether/p;" | sed "s/^.*ether b8:27:eb:\(..\):\(..\):\(..\).*/\1\2\3/" | tr '[:lower:]' '[:upper:]'`
UP_TO_DATE=$(git fetch; git status | grep "up to date" | wc -l | sed -e 's/^[[:space:]]*//')
LOG_FILE="/home/pi/WalkieTalker.log"
TALKIE_PI_CMD="/home/pi/go/bin/talkiepi"

# If hostname does not match expected value
if [ $(hostname) != "WalkieTalker-$MAC_SUFFIX" ] || [ $UP_TO_DATE != "1" ]; then
    # If FileSystemOverlay enabled
    if [ -f /boot/initrd.img-* ]; then
        # Disable FileSystem Overlay
        raspi-config nonint disable_overlayfs

        #Reboot
        reboot
    fi
    
    # Rename the Pi using the last 6 digits of the WiFi MAC Address
    hostname WalkieTalker-$MAC_SUFFIX
    raspi-config nonint do_hostname WalkieTalker-$MAC_SUFFIX

    # Update the memory split, just in case
    raspi-config nonint do_memory_split 16
    
    # Get the latest version of the script and then reboot
    cd /home/pi/WalkieTalkier
    git pull --autostash --recurse-submodules=yes; sync; reboot
fi

#If FileSystem Overlay Disabled
if [ ! -f /boot/initrd.img-* ]; then
    # Reset the ZeroTeir Configuration
    systemctl stop zerotier-one
    rm -f /var/lib/zerotier-one/identity.public
    rm -f /var/lib/zerotier-one/identity.secret

    # Enable FileSystem Overlay
    raspi-config nonint enable_overlayfs

    # Reboot
    reboot
fi

# Defaults
MUMBLE_USERNAME=$(hostname)
MUMBLE_CHANNEL="Root"

if [ -f /boot/zerotier_network.txt ]; then
    ZEROTIER_NETWORK=`cat /boot/zerotier_network.txt`
    echo "Joining ZeroTier Network: $ZEROTIER_NETWORK" > $LOG_FILE
    zerotier-cli join $ZEROTIER_NETWORK >> $LOG_FILE
fi

if [ -f /boot/mumble_server.txt ]; then
    MUMBLE_SERVER=`cat /boot/mumble_server.txt`
else
    echo "Missing /boot/mumble_server.txt" >> $LOG_FILE
    echo "WalkieTalker cannot start without a server specified. Exiting..."
    exit
fi

if [ -f /boot/mumble_channel.txt ]; then
    MUMBLE_CHANNEL=`cat /boot/mumble_channel.txt`
fi

if [ -f /boot/mumble_username.txt ]; then
    MUMBLE_USERNAME=`cat /boot/mumble_username.txt`
fi

TALKIE_PI_CMD="$TALKIE_PI_CMD -server '$MUMBLE_SERVER'"
TALKIE_PI_CMD="$TALKIE_PI_CMD -channel $MUMBLE_CHANNEL"
TALKIE_PI_CMD="$TALKIE_PI_CMD -username $MUMBLE_USERNAME"

if [ -f /boot/mumble_password.txt ]; then
    MUMBLE_PASSWORD=`cat /boot/mumble_password.txt`
    TALKIE_PI_CMD="$TALKIE_PI_CMD -password $MUMBLE_PASSWORD"
fi

echo "Executing: $TALKIE_PI_CMD" >> $LOG_FILE
/bin/bash -c "$TALKIE_PI_CMD" >> $LOG_FILE
