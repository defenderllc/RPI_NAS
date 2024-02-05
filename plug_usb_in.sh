#!/bin/sh

LOCK=/tmp/lockfile_for_plug_usb
START_DELAY_S="60"

# Get system uptime in seconds
uptime_seconds=$(cut -d. -f1 /proc/uptime)

echo "$(date -Iseconds) System has been up for $uptime_seconds seconds"

if [ -f $LOCK ]
then
        echo "$(date -Iseconds) USB drive detected. But lockfile active. Can't mount." >> /opt/usb_mon/usb_log.txt
        echo "$(date -Iseconds) USB drive detected. But lockfile active. Can't mount."
        exit 1
else
        # Check if system uptime is greater than 60s
        if [ "$uptime_seconds" -gt "$START_DELAY_S" ]; then
            echo "$(date -Iseconds) System has been up ($uptime_seconds s) for more than $START_DELAY_S seconds." >> /opt/usb_mon/usb_log.txt
            echo "$(date -Iseconds) System has been up ($uptime_seconds s) for more than $START_DELAY_S seconds."
            touch $LOCK
            echo "$(date -Iseconds) USB drive detected. Reboot to auto mount" >> /opt/usb_mon/usb_log.txt
            echo "$(date -Iseconds) USB drive detected. Reboot to auto mount"
            sleep .5
            reboot
        else
            # System uptime is less than 60s so started with USB connected. Ignore.
            echo "$(date -Iseconds) System has been up ($uptime_seconds s) for less than $START_DELAY_S seconds. Ignore USB connected." >> /opt/usb_mon/usb_log.txt
            echo "$(date -Iseconds) System has been up ($uptime_seconds s) for less than $START_DELAY_S seconds. Ignore USB connected."
        fi
fi
