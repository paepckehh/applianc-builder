#!/bin/sh
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
PNOC_DOMAIN="paepcke.de"
syntax() {
	echo "write.sclient [ sbc ] [ target drive] [ optional: zero | rnd ]"
	exit
}
verify() {
	if [ -e $STOREIMG ]; then
		echo "... verify store img [signed] hash [$STOREIMG]"
		IMGH=$(cat $STOREIMG | sha224)
	else
		IMGH=false
	fi
	if [ ! $TIMG ]; then
		case $IMGH in
		d0744bf7b50c737475ff75712c292d4dffe6f4d9fe4850e77a180f23 | 00f4962b87bc225a37268f7e1d3f02ac1c7ff498173561f9ac4cd9cf | 77fe772811cd0b2a5672752935106e40eb41c12c53c21d2600745c45 | 29bcd66c5d746147fcf81168c069c34080b31ff8712c5eb171082874)
			TIMG=$STOREIMG
			SIGNED_HASH=$IMGH
			unset OPTSRC
			PI_OS_32=true
			PI_OS_FULL=false
			;;
		da6b920cff0388cfd9e3656f1c03cf9fb6ed350b03cfa8f62ef07f13 | 8b41679315267887494d143b4025853c308e25a827b405dda677ada0)
			TIMG=$STOREIMG
			SIGNED_HASH=$IMGH
			unset OPTSRC
			PI_OS_64=true
			PI_OS_FULL=false
			;;
		*) echo "img hash unknown, exit" && exit ;;
		esac
	else
		echo "img hash unknown, exit" && exit
	fi
}

postprocess() {
	MSDOSDRIVE=/dev/"$DRIVE"s1
	LINUXDRIVE=/dev/"$DRIVE"s2
	echo "TARGET $DRIVE MSDOS: $MSDOSDRIVE LINUX: $LINUXDRIVE"
	LT=/tmp/linux
	LH=$LT/home/pi
	LE=$LT/etc
	CH=$BSD_PNOC/.client/chromium
	mkdir -p /tmp/msdos
	mkdir -p $LT
	mount -t msdosfs $MSDOSDRIVE /tmp/msdos
	mount -t ext2fs $LINUXDRIVE $LT
	# rm -rf /tmp/linux/usr/share/X11/xorg.conf.d/20-noglamor.conf
	mkdir -p /tmp/linux/etc/xdg/autostart/.disabled
	# mv -f /tmp/linux/etc/xdg/autostart/* /tmp/linux/etc/xdg/autostart/.disabled/
	PTARGET="$LH/.profile"
	URL="https://bootstrap.$PNOC_DOMAIN/chromium"
	echo "/usr/bin/xrandr --output HDMI-1 --rotate right" >> $PTARGET
	cp -rf $CH $LH/
	echo "127.0.0.1 local localhost client client.paepcke.de raspberypi" >> $LE/hosts
	mkdir -p $LH/Desktop
	mkdir -p $LH/bin
	mkdir -p $LH/store
	LIST="hq rtimeclient fsdd go-shfmt"
	if [ $FULL_CLIENT ]; then
		LIST="$LIST hq openspongeid ossp-mini go-age go-gohash go-dnscrypt-proxy go-fumpt"
	fi
	for CUR in $LIST; do
		tar -C $LH/bin -xvf $BSD_PKG/$TOS.$TARCH_L1.$TARCH_L2.$TARCH_L3/$CUR
	done
	mv -f $LH/bin/usr/bin/* $LH/bin/
	rm -rf $LH/bin/usr
	mv -f $LH/bin/root/.hq $LH/
	echo "/home/pi/bin/hq /home/pi/chromium/start.hqx" > $LH/Desktop/START.sh
	chmod 777 $LH/Desktop/*.sh
	# cp -af /tmp/msdos/cmdline.txt /tmp/msdos/cmdline.txt.old-auto
	# cp -af /usr/store/doc/pios/cmdline.txt.orig /tmp/msdos/cmdline.txt
	sync && sync && sync
	umount -f /tmp/msdos /tmp/linux
	gpart recover $DIRVE
	gpart list $DRIVE
	echo "... done!"
	beep 2
}
case $1 in
rpi2 | rpi2b32 | rpi3b32 | rpi4b32 | rpi-zero-2b32)
	STOREIMG=$BSD_IMG/.legacy/pios/current.32
	IOS=PIOS32
	TOS=linux
	TSBC=bcm2709
	. $BSD_SBC/rpi2b32
	CONFTXT='# bcm2709 config.txt
hdmi_blanking=1
camera_auto_detect=0
enable_uart=0
dtparam=sd_poll_once=on
dtparam=i2c_arm=off
dtparam=i2s=off
dtparam=spi=off
dtparam=spi=off
dtparam=audio=on
dtoverlay=vc4-fkms-v3d
max_framebuffers=1
arm_freq=900
#force_turbo=1
disable_splash=1
'
	;;

rpi2b64 | rpi3 | rpi3b64 | rpi-zero-2b64)
	STOREIMG=$BSD_IMG/.legacy/pios/current.64
	IOS=PIOS64
	TOS=linux
	TSBC=bcm2710
	. $BSD_SBC/rpi3b64
	CONFTXT='#
# bcm2710 config.txt
# program_usb_boot_mode=1 
# arm_64bit=1
# display_rotate=1
# hdmi_blanking=1
# hdmi_safe=1
# gpu_mem=128
# dtoverlay=vc4-kms-v3d
# dtoverlay=vc4-kms-v3d,noaudio
# dtoverlay=sdio,poll_once=on
# dtparam=sd_poll_once=on
# max_framebuffers=1
# enable_uart=0
# camera_auto_detect=0
# dtparam=i2c_arm=off
# dtparam=i2s=off
# dtparam=spi=off
# camera_auto_detect=0
# dtparam=audio=off
# disable_splash=1
# arm_freq=1100
# sdram_freq=480
# core_freq=480
# force_turbo=1
# over_voltage=3
# over_voltage_sdram=2
arm_freq=900
camera_auto_detect=0
dtparam=audio=on
dtoverlay=vc4-kms-v3d,noaudio
max_framebuffers=2
arm_64bit=1
enable_uart=0
'
	;;

rpi4 | rpi4b64 | rpi400 | rpi4cm)
	STOREIMG=$BSD_IMG/.legacy/pios/current.64
	IOS=PIOS64
	TOS=linux
	TSBC=bcm2711
	. $BSD_SBC/rpi4b64
	CONFTXT='# bcm2711 config.txt
#program_usb_boot_mode=1 
hdmi_blanking=1
arm_64bit=1
camera_auto_detect=0
enable_uart=0
dtparam=sd_poll_once=on
dtparam=i2c_arm=off
dtparam=i2s=off
dtparam=spi=off
dtparam=audio=on
dtoverlay=vc4-kms-v3d
dtoverlay=sdio,poll_once=on
max_framebuffers=1
#arm_freq=2000
#core_freq=500
#sdram_freq=500
#over_voltage=6
#over_voltage_sdram=2
#force_turbo=1
'
	;;

*)
	syntax
	;;
esac
if [ ! $2 ]; then syntax; fi
export DRIVE=$2
verify
case $3 in
zero)
	sh /etc/action/zerodrive $DRIVE
	;;
rnd)
	sh /etc/action/noisedrive $DRIVE
	;;
esac
if [ "$PI_OS_FULL" != "true" ]; then echo "### PI OS LIGHT / SMALL VERSION DETECTED! "; fi
if [ TIMG ]; then
	echo "### PI OS found in store! [$STOREIMG] "
	# zstdcat $STOREIMG | dd of=/dev/$DRIVE oflag=direct bs=512k status=progress
	xzcat $STOREIMG | dd of=/dev/$DRIVE oflag=direct bs=512k status=progress
else
	echo "No $1 compatible client os definition found!"
	echo "... please update script or set *** valid *** TIMG / PIOS32 or PIO64 env variables!"
	echo ""
	syntax
fi
postprocess
###########
