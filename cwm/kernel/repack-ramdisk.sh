#!/sbin/sh

# copy old kernel to sdcard
if [ ! -e /sdcard/pre_ak_zImage ]; then
	cp /tmp/boot.img-zImage /sdcard/pre_ak_zImage
fi

# decompress ramdisk
mkdir /tmp/ramdisk
cd /tmp/ramdisk
gunzip -c ../boot.img-ramdisk.gz | cpio -i

# add init.d support if not already supported
found=$(find init.rc -type f | xargs grep -oh "run-parts /system/etc/init.d");
if [ "$found" != 'run-parts /system/etc/init.d' ]; then
        #find busybox in /system
        bblocation=$(find /system/ -name 'busybox')
        if [ -n "$bblocation" ] && [ -e "$bblocation" ] ; then
                echo "BUSYBOX FOUND!";
                #strip possible leading '.'
                bblocation=${bblocation#.};
        else
                echo "NO BUSYBOX NOT FOUND! init.d support will not work without busybox!";
                echo "Setting busybox location to /system/xbin/busybox! (install it and init.d will work)";
                #set default location since we couldn't find busybox
                bblocation="/system/xbin/busybox";
        fi
		#append the new lines for this option at the bottom
        echo "" >> init.rc
        echo "service userinit $bblocation run-parts /system/etc/init.d" >> init.rc
        echo "    oneshot" >> init.rc
        echo "    class late_start" >> init.rc
        echo "    user root" >> init.rc
        echo "    group root" >> init.rc
fi

# make kernel open
cp -vr ../extras/default.prop .

# remove frequencies overrides, use kernel default
sed -i '/\/sys\/devices\/system\/cpu\/cpu0\/cpufreq\/scaling_min_freq/d' init.mako.rc
sed -i '/\/sys\/devices\/system\/cpu\/cpu1\/cpufreq\/scaling_min_freq/d' init.mako.rc
sed -i '/\/sys\/devices\/system\/cpu\/cpu2\/cpufreq\/scaling_min_freq/d' init.mako.rc
sed -i '/\/sys\/devices\/system\/cpu\/cpu3\/cpufreq\/scaling_min_freq/d' init.mako.rc

# remove mpdecision and thermald
sed -i '/mpdecision/{n; /class main$/d}' init.mako.rc
sed -i '/thermald/{n; /class main$/d}' init.mako.rc
sed -i '/mpdecision/d' init.mako.rc
sed -i '/thermald/d' init.mako.rc

# remove auditd
sed -i '/auditd/{n; /class main$/d}' init.rc
sed -i '/auditd/d' init.rc

# add AK tuning
echo "Checking for ramdisk patching ...";
if grep -q aktuning init.mako.rc; then
	echo "Found AK tunables into ramdisk! - Tuning only Ondemand";
        # add ondemand tuneables
        sed 's/scaling_governor.*/scaling_governor \"ondemand\"/' -i init.mako.rc
        sed 's/up_threshold.*/up_threshold 90/' -i init.mako.rc
        sed 's/sampling_rate.*/sampling_rate 30000/' -i init.mako.rc
        sed 's/io_is_busy.*/io_is_busy 1/' -i init.mako.rc
        sed 's/sampling_down_factor.*/sampling_down_factor 4/' -i init.mako.rc
	sed 's/optimal_freq.*/optimal_freq 918000/' -i init.mako.rc
	sed 's/sync_freq.*/sync_freq 1026000/' -i init.mako.rc
else
	# add ondemand tuneables
	sed 's/scaling_governor.*/scaling_governor \"ondemand\"/' -i init.mako.rc
	sed 's/up_threshold.*/up_threshold 90/' -i init.mako.rc
	sed 's/sampling_rate.*/sampling_rate 30000/' -i init.mako.rc
	sed 's/io_is_busy.*/io_is_busy 1/' -i init.mako.rc
	sed 's/sampling_down_factor.*/sampling_down_factor 4/' -i init.mako.rc
	sed -e 's/sampling_down_factor.*/&\n    # insert aktuning\n    write \/sys\/devices\/system\/cpu\/cpufreq\/ondemand\/down_differential 10\n    write \/sys\/devices\/system\/cpu\/cpufreq\/ondemand\/up_threshold_multi_core 60\n    write \/sys\/devices\/system\/cpu\/cpufreq\/ondemand\/down_differential_multi_core 3\n    write \/sys\/devices\/system\/cpu\/cpufreq\/ondemand\/optimal_freq 918000\n    write \/sys\/devices\/system\/cpu\/cpufreq\/ondemand\/sync_freq 1026000/' -i init.mako.rc
fi

# append ak boot at the end of init.rc
if grep -q ak-post-boot init.rc; then
        echo "Found AK kernel settings into ramdisk, nothing to do";
else
        sed 's/system\/xbin.*/system\/xbin:\/data\/ak/' -i init.environ.rc
        echo "" >> init.rc
        echo "service ak-post-boot /data/ak/ak-post-boot.sh" >> init.rc
        echo "    class core" >> init.rc
        echo "    user root" >> init.rc
        echo "    oneshot" >> init.rc
fi

# move synapse files
rm -rf res/synapse
mkdir res/synapse
chmod 755 res/synapse
cp -vr ../extras/synapse/* res/synapse

find . | cpio -o -H newc | gzip > ../newramdisk.cpio.gz
cd /
