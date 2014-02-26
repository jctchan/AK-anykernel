#!/system/bin/sh
# AK
# Godness
# Configuration
#
echo "Lets go AK ...";

# busybox shortcut
bb=/system/xbin/busybox;


$bb mount -o remount,rw /system
$bb mount -t rootfs -o remount,rw rootfs

# add synapse support
chmod 755 /res/synapse/uci
chmod 755 /res/synapse/actions/*
ln -s /res/synapse/uci /sbin/uci
/sbin/uci

$bb mount -t rootfs -o remount,ro rootfs
$bb mount -o remount,ro /system

