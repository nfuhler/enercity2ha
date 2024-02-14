#!/usr/bin/env bash


function command {
	echo $1 > /dev/ttyUSX
	sleep 1
}

# load module for ethernet interface
command "insmod /lib/modules/2.6.31/net/athrs_gmac.ko"
sleep 2
# by defaukt, the macs are uninitialized. Set it to the default value from
# devolo's init script to make it work
command "ifconfig eth1 hw ether 00:0B:3B:11:22:35"

# set ip address. Use eth1, not eth0
command "ip addr add IP dev eth1"
command "ip link set up dev eth1"

# /var is a ramfs, we need that to be writable
command "mount /var"
command "mount /proc"

# by defualt, the root fs is read only; make it writable to modify it
command "mount -o remount,rw /dev/root"

# enable the zwave chip
command "insmod /lib/modules/2.6.31/dvl_zwave_spi.ko"
command "zwprogrammer -Z on"


