#!/usr/bin/env bash


function command {
	echo $1 > /dev/ttyUSBX
	sleep 1
}

command 'setenv ipaddr IP'
command 'setenv serverip SRVIP'

command 'tftp 0x80060000 kernel.extracted.uImage'

sleep 5

command 'setenv bootargs "console=ttyS0,115200 root=1f08 rootfstype=jffs2 init=/opt/bin/shinit mtdparts=ath-nor0:320k(Bootloader),192k(BootConfig),64k(Bootflags),64k(Baptization),64k(Config1),64k(Config2),256k(free);ath-nand:1152k@0k(Kernel),13440k@1152k(Filesystem),14592k@0k(Firmware),1152k@14592k(Rescue_Kernel),13440k@15744k(Rescue_Filesystem),14592k@14592k(UpdResc),101888k@29184k(OSGI)"'

command 'bootm 0x80060000'
