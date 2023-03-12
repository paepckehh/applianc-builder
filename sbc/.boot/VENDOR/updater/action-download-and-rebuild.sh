#!/bin/sh
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
CURL="$CURL_CMD_PROXY -O "
LISTS=/tmp
ROOTDIR=/tmp && cd $ROOTDIR
DTS=$(date "+%Y%m%d")

### -> device tree sources
# URL_RPI="https://raw.githubusercontent.com/raspberrypi/linux/rpi-5.4.y/arch/arm/boot/dts"
URL_RPI="https://raw.githubusercontent.com/raspberrypi/linux/rpi-5.17.y/arch/arm/boot/dts"
URL_RPI_DEV="https://raw.githubusercontent.com/raspberrypi/linux/rpi-5.18.y/arch/arm/boot/dts"
URL_FIRMW="https://raw.githubusercontent.com/raspberrypi/firmware/master/boot"
URL_TOOLS="https://raw.githubusercontent.com/raspberrypi/tools/master"
URL_LINUX="https://raw.githubusercontent.com/torvalds/linux/master/arch/arm/boot/dts"

#### -> update fbsd head/current view
PSCI_DATE="1.20201201.g20201201"
URL_PKG="https://pkg.freebsd.org/FreeBSD:14:amd64/latest/All"
URL_PSCI="https://codeload.github.com/gonzoua/rpi3-psci-monitor/zip/master"

#### -> update uefi boot
RPI3="v1.31"
RPI4="v1.21"
URL_UEFI_RPI3="https://github.com/pftf/RPi3/releases/download/$RPI3/RPi3_UEFI_Firmware_$RPI3.zip"
URL_UEFI_RPI4="https://github.com/pftf/RPi4/releases/download/$RPI4/RPi4_UEFI_Firmware_$RPI4.zip"

#################################################################################################
check() {
	echo "... test fs status!"
	cd $ROOTDIR
	touch rwtest
	if [ $PWD != $ROOTDIR ]; then
		echo "... unable to cd into ROOTDIR!"
		exit
	fi
	if [ ! -e $ROOTDIR/rwtest ]; then
		echo "... unable to write into ROOTDIR!"
		exit:
	fi
	rm rwtest
	cd $ROOTDIR
}
################################################################################################
sortlists() {
	cd $ROOTDIR
	if [ -x /usr/bin/sponge ]; then
		SORTLIST=$(ls -I $LISTS | grep feed)
		for line in $SORTLIST; do
			cat $line | sort -u | sponge $line
		done
	fi
	echo "... sort lists done!"
}
################################################################################################
fw() {
	echo "... fetching rpi org hosted boot firmware files"
	cd $ROOTDIR
	TDIR=_rpi-fw-$DTS && mkdir -p $TDIR && cd $TDIR
	while read LINE; do
		$CURL $URL_FIRMW/$LINE
	done < $LISTS/feed.rpi-firmware
	cd ..
	cd $ROOTDIR
}
################################################################################################
overlay() {
	echo "... fetching rpi org hosted boot firmware overlay files"
	cd $ROOTDIR
	TDIR=_rpi-fw-$DTS/overlays && mkdir -p $TDIR && cd $TDIR
	while read LINE; do
		$CURL $URL_FIRMW/overlays/$LINE
	done < $LISTS/feed.rpi-firmware-overlays
	cd ../..
	cd $ROOTDIR
}
################################################################################################
rpidts() {
	echo "... fetching linux dts/dtsi build files"
	cd $ROOTDIR
	TDIR=_rpi-linux-dts-$DTS && mkdir -p $TDIR && cd $TDIR
	while read LINE; do
		$CURL $URL_RPI/$LINE
	done < $LISTS/feed.linux-dts
	while read LINE; do
		$CURL $URL_RPI/"$LINE"i
	done < $LISTS/feed.linux-dts
	grep -l "404: Not Found" * | xargs rm
	cd ..
	cd $ROOTDIR
}
################################################################################################
linuxdts() {
	echo "... fetching mainline linux dts/dtsi build files"
	cd $ROOTDIR
	TDIR=_main-linux-dts-$DTS && mkdir -p $TDIR && cd $TDIR
	while read LINE; do
		$CURL $URL_LINUX/$LINE
	done < ../feed.linux-dts
	while read LINE; do
		$CURL $URL_LINUX/"$LINE"i
	done < $LISTS/feed.linux-dts
	grep -l "404: Not Found" * | xargs rm
	cd ..
	cd $ROOTDIR
}
################################################################################################
rpidevdts() {
	echo "... fetching RPI ORG linux-dev dts/dtsi build files"
	cd $ROOTDIR
	TDIR=_rpi-linux-dev-dts-$DTS && mkdir -p $TDIR && cd $TDIR
	while read LINE; do
		$CURL $URL_RPI_DEV/$LINE
	done < $LISTS/feed.linux-dts
	cd ..
	cd $ROOTDIR
}
################################################################################################
rebuild() {
	echo "... building RPI current/dev dts mix!"
	cd $ROOTDIR
	rm -rf _rpi-linux-mix-dts-$DTS
	mkdir _rpi-linux-mix-dts-$DTS
	cd _rpi-linux-mix-dts-$DTS
	cp ../_rpi-linux57-dts-$DTS/* .
	cp ../_rpi-linux419-dts-$DTS/* .
	cd ..
	ln -fs _rpi-linux-current-dts-$DTS _rpi_linux-mix-dts-$DTS
	cd $ROOTDIR
}
################################################################################################
uboot() {
	echo "... fetching uboot inits!"
	cd $ROOTDIR
	TDIR=_uboot-$DTS
	rm -rf $TDIR > /dev/null 2>&1
	mkdir -p $TDIR && cd $TDIR
	UBOOT_DATE="2021.07_1"
	while read LINE; do
		$CURL $URL_PKG/u-boot-$LINE-$UBOOT_DATE.txz
		tar -xf u-boot-$LINE-$UBOOT_DATE.txz
		mkdir -p $LINE
		cp -f usr/local/share/u-boot/u-boot-$LINE/u-boot.bin $LINE/
		cp -f usr/local/share/u-boot/u-boot-$LINE/boot.scr $LINE/
	done < $LISTS/feed.u-boot.one
	UBOOT_DATE="2021.07_1"
	while read LINE; do
		$CURL $URL_PKG/u-boot-$LINE-$UBOOT_DATE.txz
		tar -xf u-boot-$LINE-$UBOOT_DATE.txz
		mkdir -p $LINE
		cp -f usr/local/share/u-boot/u-boot-$LINE/u-boot.bin $LINE/
		cp -f usr/local/share/u-boot/u-boot-$LINE/boot.scr $LINE/
	done < $LISTS/feed.u-boot.two
	ln -fs rpi-0-w rpi0
	ln -fs rpi-arm64 rpi3
	ln -fs rpi-arm64 rpi4
	rm -rf usr
	rm -rf +*
	cd ..
	cd $ROOTDIR
}
################################################################################################
stub() {
	echo "... fetch current fbsd fw armstub psci/gic builds!"
	cd $ROOTDIR
	TDIR=_u-psci-$DTS && mkdir -p $TDIR && cd $TDIR
	$CURL $URL_PKG/rpi-firmware-$PSCI_DATE.txz
	tar -xf rpi-firmware-$PSCI_DATE.txz
	cp usr/local/share/rpi-firmware/arm* .
	rm -rf usr
	# rm -rf *txz
	rm -rf +*
	cd ..
	cd $ROOTDIR
}
################################################################################################
stubsrc() {
	echo "... fetch current fbsd armstub psci/gic src!"
	cd $ROOTDIR
	TDIR=_u-psci-src-$DTS && mkdir -p $TDIR && cd $TDIR
	$CURL $URL_PSCI
	unzip master
	rm master
	cd ..
}
################################################################################################
rpistub() {
	echo "... fetching rpi org hosted armstub build source "
	cd $ROOTDIR
	TDIR=_rpi-tools-$DTS && mkdir -p $TDIR && cd $TDIR
	while read LINE; do
		$CURL $URL_TOOLS/$LINE
	done < $LISTS/feed.rpi-tools
	cd ..
	cd $ROOTDIR
}
################################################################################################
uefi_rpi3() {
	echo "#############################"
	echo "... fetching rpi3 uefi inits!"
	TDIR=_uefi-$DTS/RPi3 && mkdir -p $TDIR && cd $TDIR
	echo "--> $URL_UEFI_RPI3"
	$CURL -L $URL_UEFI_RPI3
	unzip RPi3_UEFI_Firmware_$RPI3.zip
	rm *zip
	cd $ROOTDIR
}
###############################################################################################
uefi_rpi4() {
	echo "#############################"
	echo "... fetching rpi4 uefi inits!"
	TDIR=_uefi-$DTS/RPi4 && mkdir -p $TDIR && cd $TDIR
	echo "--> $URL_UEFI_RPI4"
	$CURL -L $URL_UEFI_RPI4
	unzip RPi4_UEFI_Firmware_$RPI4.zip
	rm *zip
	cd $ROOTDIR
}
###############################################################################################
getpkg() {
	$CURL $URL_PKG/$PKG.txz
}
###############################################################################################
#
# GO!
#
cd $ROOTDIR
# ... choose tasks by uncomment it!
check
sortlists
# fw
# overlay
# rpidts &
# rpidevdst &
# linuxdts &
# uboot &
# stub &
# stubsrc &
# rpistub &
# uefi_rpi4 &
# uefi_rpi3 &
# rebuild
if [ $1 ]; then
	# example sh action-download-and-rebuild.sh zig-0.8.1
	# defaults to amd64 current all
	PKG=$1
	getpkg
	exit
fi
wait
sync && sync && sync
echo "... done!"
exit
################################################################################################
