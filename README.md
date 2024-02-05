# RPI NAS
This runs OpenMediaVault on an RPI to provide a network share on a USB drive that Axis Cameras can record video and Tracker App telemetry logs to.
The USB drive can then be removed and inserted into a C2 player server to upload videos to local storage on that server.

===================================================================================================
# C2 Video Import Usage
===================================================================================================
- Insert the USB into the C2 RPI server.
- Click on the Archive tab and then the camera for which you wish to import files for.
  - NOTE: This is important you select the correct camera as the files don't have anything to determine what camera they are from.
- Click "Import videos from C2 USB".
- This will then scan the USB drive for video files and copy them to the C2 RPI archive location. At the same time renaming to the correct naming format.
  - There is a status message to show where it is up to.
- You need to then refresh the archive tab and the videos will be there to play.

===================================================================================================
## RPI-NAS Usage
===================================================================================================
NOTE:
- You cannot connect the USB to the RPI-NAS for the first 60s while the RPI is booting up. New connections of USB drive are ignored during this time. Best practice is to plug the USB into the RPI-NAS before booting/powering on.

===================================================================================================
## NAS Storage Setup On AXIS Camera
===================================================================================================
NOTE: This must be done after setting up the Open Media Vault NAS.

http://10.147.18.18/camera/index.html#/system/storage

System -> Storage -> Network Storage
Click Set up
Add details as below

Host: 		 192.168.4.1      (IP address of the RPI NAS360)
Share: 		 NAS360
Security: 					        (The RPI creds)
SMB: 		   Auto         	  (Left this as default Auto seems to work)

===================================================================================================
## RPI Setup
===================================================================================================
https://www.techradar.com/how-to/computing/how-to-build-your-own-raspberry-pi-nas-1315968
https://www.youtube.com/watch?v=gyOHTZvhnxY&t=317s
- Good guide for setup of clean system

### Need to have a clean install of "Raspberry Pi Lite OS 32-bit"
NOTE: Only Debian 10 (Buster) and 11 (Bullseye) are supported.  Exiting..

### Install Packages
curl -s https://install.zerotier.com | sudo bash
sudo apt update
sudo apt upgrade -y
This one might overwrite netowrk: 
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash

### Open Media Vault (OMV) Configuration
Go to the RPI IP in your browser to open the OMV dashboard (before restarting) and login with below credentials.
User: admin
Pwd: openmediavault

### Setup of USB Drive (see guide above for more details):
Storage > Disks and click the Scan button to make OpenMediaVault aware of the disks
  - Wipe - to clean each disk individually (make sure it is USB and not the main disk). NOTE: This will reformat drive and clear any videos on there.
Storage > File Systems to create a filesystem on the drive
  - Click the + icon to create a new Ext4
  - Link to the USB you just wiped
  - Once finished click the Mount button
  - Apply the pending changes
Storage > Shared Folders 
  - Click + icon to create new Share
  - Name it 'NAS360'
  - Select the filesystem you created
  - Use default created relative path i.e NAS360/
  - Permissions: Set to Everyone: read/write
  - Click Save and then Apply the pending changes
Services > SMB/CIFS > Shares
  - Click the + icon
  - Add the share just created
  - Public: Guests allowed
  - Click save
Services > SMB/CIFS > Settings
  - Check Enabled
  - Keep the rest as default
  - Click save
  - Apply the pending changes

### Auto detect USB

sudo mkdir /opt/usb_mon

#### udev rule
sudo nano /etc/udev/rules.d/99-plug_usb.rules
```
# cat /etc/udev/rules.d/plug_usb.rules
ACTION=="add", SUBSYSTEM=="usb", PROGRAM="/opt/usb_mon/plug_usb_in.sh"
ACTION=="remove", SUBSYSTEM=="usb", PROGRAM="/opt/usb_mon/plug_usb_out.sh"
```

sudo udevadm control --reload-rules

#### Plug in script
sudo nano /opt/usb_mon/plug_usb_in.sh
```
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
        #if [ $(echo "$uptime_seconds > $START_DELAY_S" | bc -l) -eq 1 ]; then
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

```

sudo chmod +x /opt/usb_mon/plug_usb_in.sh

#### plug out script
sudo nano /opt/usb_mon/plug_usb_out.sh
```
#!/bin/sh

LOCK=/tmp/lockfile_for_plug_usb
/bin/rm -f /tmp/lockfile_for_plug_usb
echo "$(date -Iseconds) USB drive removed. Clear lock file" >> /opt/usb_mon/usb_log.txt
lsusb | grep Disk >> /opt/usb_mon/usb_log.txt
```

sudo chmod +x /opt/usb_mon/plug_usb_out.sh

## Debugging
### Monitor USB log
cat /opt/usb_mon/usb_log.txt
- Debug log

### udev Debugging
sudo udevadm control --log-priority=debug
- Temporary change the logging from error to debug for current running udev. Will reset to /etc/udev/udev.conf on restart
journalctl -f -n 50
- Follow and tail last 50 lines
- You should see your udev script called here


sudo udevadm info --name /dev/sda1 --query all
- Use this to get all the attributes you can use to filter it on

sudo udevadm control --reload-rules

sudo udevadm monitor

sudo sudo udevadm test -a add $(udevadm info -q path -n /dev/sda1)

udevadm test $(udevadm info --query=path --name=device_name)

sudo udevadm info --attribute-walk --name /dev/sda

### Check if USB drive is mounted
lsblk

### Test unmounting
sudo umount /dev/sda1
