#Get the last 6 digits of the WiFi MAC Address
MAC_SUFFIX=`ifconfig wlan0 | sed -n "/ether/p;" | sed "s/^.*ether b8:27:eb:\(..\):\(..\):\(..\).*/\1\2\3/" | tr '[:lower:]' '[:upper:]'`

# If hostname does not match expected value
if [ $(hostname) != "WalkieTalker-$MAC_SUFFIX" ]; then
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

    # Restart with the new hostname
    reboot
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

TALKIE_PI_CMD="/home/pi/go/bin/talkiepi"

if [ -f /boot/mumble_server.txt ]; then
    MUMBLE_SERVER=`cat /boot/mumble_server.txt`
    TALKIE_PI_CMD="$TALKIE_PI_CMD -server '$MUMBLE_SERVER'"
fi

if [ -f /boot/mumble_username.txt ]; then
    MUMBLE_USERNAME=`cat /boot/mumble_username.txt`
    TALKIE_PI_CMD="$TALKIE_PI_CMD -username '$MUMBLE_USERNAME'"
fi

if [ -f /boot/mumble_password.txt ]; then
    MUMBLE_PASSWORD=`cat /boot/mumble_password.txt`
    TALKIE_PI_CMD="$TALKIE_PI_CMD -password '$MUMBLE_PASSWORD'"
fi

if [ -f /boot/mumble_channel.txt ]; then
    MUMBLE_CHANNEL=`cat /boot/mumble_channel.txt`
    TALKIE_PI_CMD="$TALKIE_PI_CMD -channel '$MUMBLE_CHANNEL'"
fi

echo Executing: $TALKIE_PI_CMD | tee /home/pi/WalkieTalker.log
/bin/bash -c "$TALKIE_PI_CMD" | tee /home/pi/WalkieTalker.log
