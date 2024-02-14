# enercity2ha
Lately, the energy provider enercity has been giving away 2 free zwave
thermostats including a smarthome gateway.
Because I wanted to use the thermostats from Home Assistant without enercity's
platform, I modified the included gateway to be compatible with existing uart
zwave integrations.

# Getting Access to the gateway
The gateway is the "Smart Building Gateway MT 2683" by rockethome. As it turns
out, it is a devolo Home Control Central Unit with modified software.
[1] Describes how to get uart access to the gateway and how to optain kernel and
filesystem images from it.
I would recommend dumping the filesystem so it can be restored if you mess
something up.

# Creating  a Kernel Image
Because devolo uses its custom boot command, it is not possible to simply change
the kernel command line to init=/bin/sh. Instead, you have to create a bootable
kernel image and boot it via tftp.
Unfortunately, the kernel image optained in [1] is not an ordinary uImage but
a uImage wrapped in devolo's proprietary image. By removing the first X byte of
the file, you can optain a standard uImage.

The kernel in the uImage is lzma compressed. Because the u-Boot version on the
gateway contains a bug, it is not able to extract itself at boot. Because of
that, you have to optain the raw kernel image from the uImage (again by removing
the first x bytes). You can than extract the compressed kernel and generate a
new image containing the uncompressed kernel using `mkimage`.

# Booting the Kernel
The Kernel can the be booted via tftp. You can find the commands in
`boot_kernel.sh`. Modify it to your needs if you do not want to type the
commands on every reboot.

# Building binaries
We will need socat to connect to the serial port over a tcp tunne. Because the
gateway is running a very old kernel 2.6, wen need to build a version of socat
old enough to run on this kernel. Unfortunately, we also need to build a version
that is new enough as the asserts in old socat versions are not endian-safe.
I found that version 1.7.2.0 works.

You can cross compile it under Debian 12 with `gcc-linux-mips-gnu`. Of course,
it has to be linked statically.
I also found it useful during debugging to have a modern version of busybox, so
I cross compiled version 1.36.1 the same way.

# Uploading the binaries
Once we have booted into a shell via tftp, there are a couple of things needing
initialization.
You can find everything I had to initialize in the `init_system.sh`. Please modify
it to your needs before you use it.

When the system is initialized, you can place the compiled busybox, socat and
`shinit` script (this will become our new init) into `/opt/bin/`.
Unfortunately, there was not enough space on the file system, so I opted to
delete /usr/www as we do not need it anymore.

# DHCP
Our new init performs dhcp and needs a script to be executed when the state of
an interface changes. I copied the one that already exists in X to /opt/ and
commented the actions I wanted back in.

# Modifying u-Boot
Now it's time to make the gateway boot the modified system permanently.
Load the kernel image via tftp and write it to the flash. There are a few bad
blocks, I found putting it to address `0x1c80000` worked on my unit.
Set the bootargs to `bootargs=console=ttyS0,115200 root=1f08 rootfstype=jffs2 init=/opt/bin/shinit mtdparts=ath-nor0:320k(Bootloader),192k(BootConfig),64k(Bootflags),64k(Baptization),64k(Config1),64k(Config2),256k(free);ath-nand:1152k@0k(Kernel),13440k@1152k(Filesystem),14592k@0k(Firmware),1152k@14592k(Rescue_Kernel),13440k@15744k(Rescue_Filesystem),14592k@14592k(UpdResc),101888k@29184k(OSGI)`
and the bootcmd to `nand read 0x80060000 0x1c80000 0x331240 && bootm
0x80060000`.
Save the new configureation with `saveenv`.

# Attaching to the serial port
When your Gateway boots now, it will have an open telnet port as well as port
5555.
You can now create a virtual tty to attach to using `socat tcp:IP:5555
pty,link=ttyZ,raw,echo=0`. This tty can be passed to the zwave-js docker
container. Please note that `--device` does not work for this and you need to
use `-v`.
Of course it is not ideal to have a device with an open telnet in your home
network, so this device got its own vlan in my setup where only it and the home
assistant have access.

[1] https://gist.github.com/7marcus9/d46bd16fda8fa2c736a09c4dadd0621e
