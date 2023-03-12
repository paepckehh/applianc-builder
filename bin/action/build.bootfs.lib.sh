#!/bin/sh
####################################
### CONFIGURATION SETUP SECTION  ###
####################################
build_bootfs_config() {
}
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
build_bootfs_loader_entropy() {
	mkdir -p $BOOTFS/boot
	dd if=/dev/random bs=4096 count=1 status=none of=$BOOTFS/boot/entropy oflag=direct
}
build_bootfs_loader_config_file() {
	case $TARGETARCH in
	armv7) BSD_LOADER_CONF="$BSD_LOADER_CONF
kern.maxswzone=65536000" ;;
	esac
	case $XBOOT in
	ubldr) export BSD_LOADER_CONF="$(echo "$BSD_LOADER_CONF" | sed -e 's/vidconsole/uboot/g')" ;;
	esac
	if [ -n "$BSD_LOADER_CONF" ]; then echo "$BSD_LOADER_CONF" > $BOOTFS/boot/defaults/loader.conf; fi
	if [ -n "$BSD_LOADER_CONF_SYSCTL" ]; then echo "$BSD_LOADER_CONF_SYSCTL" >> $BOOTFS/boot/defaults/loader.conf; fi
	if [ -n "$BSD_DEVICE_HINTS" ]; then echo "$(echo "$BSD_DEVICE_HINTS" | sort -u)" > $BOOTFS/boot/device.hints; fi
}
build_bootfs_loader_efi() {
	if [ -z $EFI_LOADER_SRC ]; then
		EFI_LOADER_SRC=/usr/obj/usr/src/$SRC_CHECKOUT/$TARGET.$TARGETARCH/stand/efi/loader_lua/loader_lua.efi
	fi
	BOOT_EFI=$BOOTFS/EFI/BOOT && mkdir -p $BOOT_EFI
	echo "### LOADER INSTALL EFI : $TARGETARCH XBOOT: $XBOOT BOOT_EFI_NAME: $BOOT_EFI_NAME"
	cp -vf $EFI_LOADER_SRC $BOOT_EFI/$BOOT_EFI_NAME
}
build_bootfs_loader_lua() {
	export BSD_LOG_DIR=/tmp/.build.logs && mkdir -p $BSD_LOG_DIR
	MAKEDIR="/usr/src/$SRC_CHECKOUT/stand/lua"
	MAKECMD="$MAKE -j $JFLAG TARGET=$TARGET TARGET_ARCH=$TARGETARCH DESTDIR=$BOOTFS install"
	MAKELOG=$BSD_LOG_DIR/ok.make.lua.bootfs.$TARCH_TRIPLE.$BSD_TARGET_SBC-$BSD_TARGET_DIST.$DTS
	echo "### LOADER LUA FILES INSTALL: $MAKEDIR $MAKECMD"
	cd $MAKEDIR && $MAKECMD > $MAKELOG
}
build_bootfs_loader_install() {
	echo "### LOADER INSTALL: $TARGETARCH XBOOT: $XBOOT"
	case $TARGETARCH in
	amd64)
		BOOT_SRC=/usr/obj/usr/src/$SRC_CHECKOUT/$TARGET.$TARGETARCH/stand/i386
		mkdir -p $BOOT_R
		case $XBOOT in
		ubldr) echo "... aarch64 has no ubldr support! [ERROR EXIT]" && exit ;;
		uefi | efi) BOOT_EFI_NAME=bootx86.efi && build_bootfs_loader_efi ;;
		gptboot)
			BOOT_FALLBACK=true
			case $BOOT_FALLBACK in
			true)
				echo "... fallback bootloader!"
				for PART in gptboot pmbr; do
					cp -vf $BSD_GIT/.bsd-boot/_x86/$PART $BOOT_R/$PART
				done
				cp -vf $BSD_GIT/.bsd-boot/_x86/loader $BOOTFS/boot/loader
				;;
			*)
				for PART in gptboot pmbr; do
					cp -vf $BOOT_SRC/$PART/$PART $BOOT_R/$PART
				done
				cp -vf $BOOT_SRC/loader_lua/loader_lua $BOOTFS/boot/loader
				;;
			esac
			;;
		mbrboot)
			cp -vf $BOOT_SRC/mbr/mbr $BOOT_R/mbr
			cp -vf $BOOT_SRC/loader_lua/loader_lua $BOOTFS/boot/loader
			;;
		bsdboot)
			cp -vf $BOOT_SRC/boot/boot $BOOT_R/boot
			cp -vf $BOOT_SRC/loader_lua/loader_lua $BOOTFS/boot/loader
			;;
		esac
		;;
	armv6)
		case $XBOOT in
		ubldr) echo "... armv6 ubldr support terminated! [ERROR EXIT]" && exit ;;
		efi) BOOT_EFI_NAME=bootarm.efi && build_bootfs_loader_efi ;;
		esac
		;;
	armv7)
		case $XBOOT in
		ubldr) echo "... secure armv7 ublr boot mode unlocked" ;;
		efi) BOOT_EFI_NAME=bootarm.efi && build_bootfs_loader_efi ;;
		esac
		;;
	aarch64)
		case $XBOOT in
		ubldr) echo "... aarch64 has no ubldr support! [ERROR EXIT]" && exit ;;
		efi) BOOT_EFI_NAME=bootaa64.efi && build_bootfs_loader_efi ;;
		esac
		;;
	esac
}
build_boofs_vendor_boot() {
	unset BSD_DEVICE_HINTS BSD_VENDOR_BOOT && . $BSD_SBC/$BSD_TARGET_SBC
	cp -rf $BSD_BOOT/VENDOR/$BSD_VENDOR_BOOT/* $BOOTFS/
}
build_bootfs_main() {
	if [ $BSD_VENDOR_BOOT ]; then (build_boofs_vendor_boot); fi
	build_bootfs_loader_entropy &
	build_bootfs_loader_lua &
	build_bootfs_loader_install &
	build_bootfs_loader_config_file &
	wait && sync
	XCMD="sh $BSD_ACTION/.create.img.sh $BOOTFSIMG $BOOTFS $BOOT_FBSD_FS none bootfs nofsck" && echo $XCMD && $XCMD
}
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
build_bootfs() {
	build_bootfs_main
}
####################################
