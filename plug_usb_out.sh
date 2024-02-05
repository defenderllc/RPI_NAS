#!/bin/sh

LOCK=/tmp/lockfile_for_plug_usb
/bin/rm -f /tmp/lockfile_for_plug_usb
echo "$(date -Iseconds) USB drive removed. Clear lock file" >> /opt/usb_mon/usb_log.txt
