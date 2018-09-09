#!/bin/bash

MountOSXESP() {
    # Identify the ESP. Note: This returns the FIRST ESP found;
    # if the system has multiple disks, this could be wrong!
    Temp=$(mount | sed -n -E "/^(\/dev\/disk[0-9]+s[0-9]+) on \/ \(.*$/s//\1/p")
    if [ $Temp ]; then
        Temp=$(diskutil list | grep " EFI " | grep -o 'disk.*' | head -n 1)
        if [ -z $Temp ]; then
            echo "Warning: root device doesn't have an EFI partition"
        fi
    else
        echo "Warning: root device could not be found"
    fi
    if [ -z $Temp ]; then
        Temp=$(diskutil list | sed -n -E '/^ *[0-9]+:[ ]+EFI EFI[ ]+[0-9.]+ [A-Z]+[ ]+(disk[0-9]+s[0-9]+)$/ { s//\1/p
                q
            }' )

        if [ -z $Temp ]; then
            echo "Could not find an EFI partition. Aborting!"
            exit 1
        fi
    fi
    Esp=/dev/`echo $Temp`
    echo "The ESP has been identified as $Esp; attempting to mount it...."
    # If the ESP is mounted, use its current mount point....
    Temp=`df -P | grep "$Esp "`
    MountPoint=`echo $Temp | cut -f 6- -d ' '`
    if [[ "$MountPoint" == '' ]] ; then
        if [[ $UID != 0 ]] ; then
            echo "You must run this program as root or using sudo!"
            exit 1
        fi
        MountPoint="/Volumes/ESP"
        mkdir /Volumes/ESP &> /dev/null
        mount -t msdos "$Esp" $MountPoint
        # Some systems have HFS+ "ESPs." They shouldn't, but they do. If this is
        # detected, mount it as such and set appropriate options.
        if [[ $? != 0 ]] ; then
            mount -t hfs "$Esp" $MountPoint
            if [[ $? != 0 ]] ; then
                echo "Unable to mount ESP!\n"
                exit 1
            fi
        fi
    fi
    echo "The ESP is mounted at $MountPoint"
} # MountOSXESP()

#
# Main part of script....
#

case "$OSTYPE" in
    darwin*)
            MountOSXESP
            ;;
    *)
            echo "This script is meant to be run under macOS *ONLY*! Exiting!"
            exit
            ;;
esac
