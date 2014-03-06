#!/system/bin/sh
# AK
# Godness
# Configuration
#
echo "Lets go AK ...";

# busybox shortcut
bb=/data/ak/busybox;

# remount system and rootfs into rw
$bb mount -o remount,rw /system
$bb mount -t rootfs -o remount,rw rootfs

# add synapse support
chmod 755 /res/synapse/uci
ln -s /res/synapse/uci /sbin/uci
/sbin/uci

# remount system and rootfs into ro
$bb mount -t rootfs -o remount,ro rootfs
$bb mount -o remount,ro /system

