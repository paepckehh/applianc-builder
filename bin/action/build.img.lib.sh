#!/bin/sh
####################################
### CONFIGURATION SETUP SECTION  ###
####################################
build_config() {
	. $BSD_SBC/.alias/$BSD_TARGET_SBC
	. $BSD_DIST/$BSD_TARGET_DIST
	export TARCH_TRIPLE=$TARCH_L1.$TARCH_L2.$TARCH_L3
	export KERNCONF=$BSD_TARGET_SBC-$BSD_TARGET_DIST
	export UUID=$(uuidgen | cut -c 1-8)
	export FSUUID=/tmp/.build.$UUID.$(date "+%Y%m%d%H%M%S")
	export ROOTFS=$FSUUID.ROOTFS && mkdir -p $ROOTFS && mount -t tmpfs tmpfs $ROOTFS
	export BOOTFS=$FSUUID.BOOTFS && mkdir -p $BOOTFS && mount -t tmpfs tmpfs $BOOTFS
	export BOOTFSIMG=$FSUUID.IMG
	export BUILDTS=/tmp/.build.logs/$UUID.ts
	export IMGBASE="/tmp/.build.img.unsigned"
	export OUTIMG="$IMGBASE/$BSD_TARGET_DIST.$BSD_TARGET_SBC.$TARCH_L1.$TARCH_L2.$TARCH_L3.$XBOOT"
	export BOOT_R=$BOOTFS/boot_recover
	mkdir -p $BOOTFS/boot/kernel $BOOTFS/boot/defaults $ROOTFS/etc $IMGBASE
	if [ ! $TOS ]; then export TOS=fbsd; fi
	INFO="START_IMG" && build_info
	echo "... boot mode: $XBOOT [env override: $XBOOT_ENFORCE]"
}
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
build_prep_src() {
	sh $BSD_ACTION/build.src.lib.sh build_src $SRC_CHECKOUT
}
build_prep_ccache_action() {
	if [ ! -x /usr/ccache/$LINE/0 ]; then
		mkdir -p /usr/ccache/$LINE
		if [ -e /dev/md$MD ]; then mdconfig -d -u $MD > /dev/null 2>&1; fi
		mdconfig -u $MD -o async -f $BSD_CCACHE/$LINE
		mount -r /dev/md$MD.uzip /usr/ccache/$LINE
	fi
}
build_prep_ccache() {
	echo "... staging secure signed /usr/ccache[s]"
	if [ ! -w /usr/ccache/.temp ]; then mount -t tmpfs tmpfs /usr/ccache && mkdir -p /usr/ccache/.temp; fi
	export MD=$BSD_MD_CCACHE_START
	LIST=$(ls -I $BSD_CCACHE)
	for LINE in $LIST; do
		build_prep_ccache_action &
		export MD=$((MD + 1))
	done
	wait
}
build_prep_env() {
	sh /etc/.bsdconf rebuild_store
	if [ ! -e /usr/src/$SRC_CHECKOUT/Makefile ]; then
		build_prep_src &
	fi
	if [ ! $BSD_CCACHE_REBUILD_MODE ]; then
		build_prep_ccache &
	fi
	(sh /etc/action/clean.path /usr/obj TMPFS) &
	wait
}
build_ccache_config() {
	if [ $BSD_CCACHE_REBUILD_MODE ]; then
		echo "... cache rebuild mode!"
	else
		echo "... use ccache mode!"
		unset CCACHE_NOREADONLY
		export CCACHE_READONLY=true
		export CCTARGET=$TOS.$SRC_CHECKOUT.$TARGET.$TARGETARCH.$TCPUTYPE
		export CCACHE_DIR=/usr/ccache/$CCTARGET
		export WITH_CCACHE_BUILD=true
		ln -fs /usr/bin/ccache /usr/local/bin/ccache # XXX FBSD FIX, use CCACHE_BIN if avail, not hardcoded path
		if [ ! $CACHE_DONE ]; then
			build_prep_src_cache &
			build_prep_ccache_cache_current_target &
		fi
	fi
}
build_prep_src_cache() {
	echo "... mem-cache /usr/src"
	find /usr/src -type f | xargs cat > /dev/null 2>&1
}
build_prep_ccache_cache_mt() {
	echo "... mem-cache /usr/ccache multithreaded!"
	LIST=$(ls -I /usr/ccache)
	for LINE in $LIST; do
		(find /usr/ccache/$LINE -type f | xargs cat > /dev/null 2>&1) &
	done
	wait
}
build_prep_ccache_cache_current_target() {
	echo "... mem-cache /usr/ccache $CCACHE_DIR!"
	find $CCACHE_DIR -type f | xargs cat > /dev/null 2>&1
}
build_prep_ccache_cache_all() {
	echo "... startup mem-cache resources! Please wait!"
	build_prep_env
	build_prep_src_cache &
	build_prep_ccache_cache_mt
	wait
	export CACHE_DONE=true
	echo "... end mem-cache resources!"
}
build_info() {
	DTS=$(date "+%Y%m%d-%H%M%S")
	if [ "$EMBEDDED" == "true" ]; then EMB="EMBEDDED -> true"; fi
	echo "#####################################################################################################################"
	echo "$INFO $DTS $BSD_TARGET_SBC, $BSD_TARGET_SOC, $BSD_TARCH_TRIPLE,  $BSD_TARGET_DIST, $EMB"
	echo "#####################################################################################################################"
}
build_img_main() {
	build_config
	build_prep_env
	build_ccache_config
	. $BSD_ACTION/build.make.lib.sh
	case $BMODE in
	worldonly)
		(make_buildworld)
		;;
	kernelonly)
		(make_buildkernel)
		(make_storekernel)
		;;
	*)
		(make_buildworld)
		(make_buildkernel)
		(make_installkernel)
		if [ ! $BSD_CCACHE_REBUILD_MODE ]; then
			. $BSD_ACTION/build.root.lib.sh
			. $BSD_ACTION/build.bootfs.lib.sh
			build_root
			build_bootfs
			. $BSD_SBC/$BSD_TARGET_SBC
			case $BOOT_FBSD_FS in
			msdos*) PART="$BOOT_FBSD_BOOTPARTS -p fat32:=$BOOTFSIMG" ;;
			ffs*) PART="$BOOT_FBSD_BOOTPARTS -p freebsd-ufs:=$BOOTFSIMG" ;;
			esac
			XCMD="/usr/bin/mkimg -s $BOOT_FBSD_SCHEME -f $BOOT_FBSD_IMG $PART -p- -p- -o $OUTIMG"
			echo $XCMD && $XCMD

		fi
		;;
	esac
	umount -f $BOOTFS $ROOTFS > /dev/null 2>&1
	rm -rf $BOOTFS $ROOTFS $BOOTFSIMG > /dev/null 2>&1
	INFO="END_IMG" && build_info && sync
}
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
build_img() {
	build_img_main
}
build_prepcache() {
	build_prep_ccache_cache_all
}
####################################
###  EXTERNAL COMMAND INTERFACE  ###
####################################
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
case $1 in
build) build_img ;;
prepcache) build_prepcache ;;
esac
###################################
