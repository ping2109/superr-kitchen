#!/sbin/sh

## configure.sh by SuperR. @XDA

## Do not edit this file unless you know what you are doing

# Set conf file location
if [ -d /tmp ]; then
	rm -rf /tmp/config /tmp/rootzip
	CONF_FILE="/tmp/config"
else
	rm -rf /sdcard/srk_config
	CONF_FILE="/sdcard/srk_config"
fi

# Get slot if it exists
SLOT=$(getprop ro.boot.slot_suffix)
if [ -z $SLOT ]; then
	SLOT=_$(getprop ro.boot.slot)
	if [ "$SLOT" = "_" ]; then
		SLOT=
	fi
fi
if [ -z $SLOT ]; then
	SLOT=$(cat /proc/cmdline 2>/dev/null | tr ' ' '\n' | grep slot | grep -v simslot | cut -d'=' -f2)
fi
if [ -n $SLOT ]; then
	if [ "$SLOT" = "_a" ] || [ "$SLOT" = "_b" ]; then
		echo "slotnum=$SLOT" >> $CONF_FILE
	else
		SLOT=
	fi
fi

# Get system partition and by-name paths
SYSTEMBLOCK=$(find /dev/block | grep -i "system$SLOT" | head -n 1)
if [ -z $SYSTEMBLOCK ]; then
	for i in /etc/*fstab*; do
		SYSTEMBLOCK=$(grep -v '#' $i | grep -E '/system[^a-zA-Z]' | grep -v system_image | grep -v mmcblk | grep -oE '/dev/[a-zA-Z0-9_./-]*')
		if [ -n $SYSTEMBLOCK ]; then
			break
		fi
	done
fi
if [ -n $SYSTEMBLOCK ] && [ $(readlink -f "$SYSTEMBLOCK") ]; then
	BYNAME=$(dirname "$SYSTEMBLOCK")
	echo "byname=$BYNAME" >> $CONF_FILE
else
	echo "fail=fail" >> $CONF_FILE
	exit 1
fi

# Check for system_root mount point
if [ -d /system_root ]; then
	echo "sysmnt=/system_root" >> $CONF_FILE
else
	echo "sysmnt=/system" >> $CONF_FILE
fi

# Add verified partitions to $CONF_FILE
for i in system SYSTEM APP; do
	if [ $(readlink -f "$BYNAME/$i$SLOT") ]; then
		echo "system=$BYNAME/$i$SLOT" >> $CONF_FILE
		break
	fi
done
for i in vendor VENDOR VNR; do
	if [ $(readlink -f "$BYNAME/$i$SLOT") ]; then
		echo "vendor=$BYNAME/$i$SLOT" >> $CONF_FILE
		break
	fi
done
for i in userdata USERDATA UDA; do
	if [ $(readlink -f "$BYNAME/$i$SLOT") ]; then
		echo "data=$BYNAME/$i$SLOT" >> $CONF_FILE
		break
	fi
done
for i in system_ext version product optics prism cust oem odm ODM recovery RECOVERY ramdisk RAMDISK kernel KERNEL Kernel; do
	PART="$(echo "$i" | tr '[:upper:]' '[:lower:]')"
	if [ $(grep "$PART=" $CONF_FILE) ]; then
		continue
	fi
	if [ $(readlink -f "$BYNAME/$i$SLOT") ]; then
		echo "$PART=$BYNAME/$i$SLOT" >> $CONF_FILE
	fi
done

# Get boot partition and by-name paths
BOOTBLOCK=
for i in boot BOOT LNX; do
	if [ $(readlink -f "$BYNAME/$i$SLOT") ]; then
		BOOTBLOCK="$BYNAME/$i$SLOT"
		echo "boot=$BOOTBLOCK" >> $CONF_FILE
		break
	fi
done
if [ -z $BOOTBLOCK ]; then
	for i in boot LNX; do
		BOOTBLOCK=$(find /dev/block | grep -i "$i$SLOT" | head -n 1)
		if [ -n $BOOTBLOCK ]; then
			echo "boot=$BOOTBLOCK" >> $CONF_FILE
			break
		fi
	done
fi
