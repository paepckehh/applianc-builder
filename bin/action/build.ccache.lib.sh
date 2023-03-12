#!/bin/sh
####################################
### CONFIGURATION SETUP SECTION  ###
####################################
ccache_setup() {
	export BSD_REBUILD_CCACHE_MODE=true
	sh $BSD_ACTION/build.src.lib.sh build_src
	if [ ! -x /usr/local/bin/ccache ]; then ln -fs /usr/bin/ccache /usr/local/bin/ccache; fi
	umount -f /usr/obj > /dev/null 2>&1
	mount -t tmpfs tmpfs /usr/obj
}
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
ccache_prep() {
	. $BSD_SBC/$CCSBC
	export CCTARGET=$TOS.$SRC_CHECKOUT.$TARGET.$TARGETARCH.$TCPUTYPE
	echo -n "... check ccache for   $CCTARGET   "
	if [ ! -e $BSD_CCACHE/$CCTARGET ]; then
		if [ -e $BSD_CONF/patch.auto.rollback/900-* ]; then
			echo "Please remove the 900er auto-rollback-pointless-ccache-trash-only-spam patches and rebuild the src tree!"
			sh /etc/action/beep ERR
			exit
		fi
		MD=$BSD_MD_CCACHE_START
		LIST=$(ls -I /usr/ccache)
		for LINE in $LIST; do
			umount /usr/ccache/$LINE > /dev/null 2>&1
			if [ -x /usr/ccache/$LINE/0 ]; then umount -f /usr/ccache/$LINE; fi
			if [ -e /dev/md$MD ]; then mdconfig -d -u $MD -o force > /dev/null 2>&1; fi
			MD=$((MD + 1))
		done
		umount -f /usr/ccache > /dev/null 2>&1
		umount -f /usr/obj > /dev/null 2>&1
		mount -t tmpfs tmpfs /usr/obj
		mount -t tmpfs tmpfs /usr/ccache && mkdir -p /usr/ccache/.temp
		echo " 	 -> [rebuilding now!]"
	else
		echo " 	 -> [ok]"
	fi
}
ccache_build() {
	. $BSD_SBC/$CCSBC
	export CCTARGET=$TOS.$SRC_CHECKOUT.$TARGET.$TARGETARCH.$TCPUTYPE
	if [ ! -e $BSD_CCACHE/$CCTARGET ]; then
		unset CCACHE_READONLY
		export CCACHE_NOREADONLY=true
		export CCACHE_DIR=/usr/ccache/$CCTARGET && mkdir -p $CCACHE_DIR
		export WITH_CCACHE_BUILD=true
		export BSD_CCACHE_REBUILD_MODE=true
		echo "... starting ccache build for $TARGET $TARGETARCH $TCPUTYPE $DIST EMBEDDED $EMBEDDED"
		echo "... starting ccache build for $TARGET $TARGETARCH $TCPUTYPE $DIST EMBEDDED $EMBEDDED" > /dev/stdout
		time -h sh $BSD_ACTION/build.img.lib.sh build >> $LOGM 2>&1
	fi
}
ccache_snap() {
	. $BSD_SBC/$CCSBC
	export CCTARGET="$TOS.$SRC_CHECKOUT.$TARGET.$TARGETARCH.$TCPUTYPE"
	if [ ! -e $BSD_CCACHE/$CCTARGET ]; then
		export CCACHE_DIR=/usr/ccache/$CCTARGET && mkdir -p $CCACHE_DIR
		echo "... taking a ccache dump snapshot for $CCTARGET $BSD_TARGET_SBC $BSD_TARGET_DIST!"
		echo "... taking a ccache dump snapshot for $CCTARGET $BSD_TARGET_SBC $BSD_TARGET_DIST!" > /dev/stdout
		mkdir -p $BSD_CCACHE/.store
		IMG=$BSD_CCACHE/.store/$CCTARGET.$(date "+%Y%m%d")
		XCMD="sh $BSD_ACTION/.create.img.sh $IMG $CCACHE_DIR ffs1 zstd ccache$TARGETARCH" && echo $XCMD && $XCMD
		(cd $BSD_CCACHE && ln -s $IMG $CCTARGET)
		umount -f /usr/ccache /usr/obj > /dev/null 2>&1
	fi
}
ccache_build_all_dists() {
	. $BSD_SBC/$CCSBC
	export CCTARGET="$TOS.$SRC_CHECKOUT.$TARGET.$TARGETARCH.$TCPUTYPE"
	if [ ! -e $BSD_CCACHE/$CCTARGET ]; then
		LIST="bsrv"
		case $SBC in
		rpi2b32) LIST="$LIST cssh pnoc" ;;
		esac
		for LINE in $LIST; do
			export BSD_TARGET_DIST=$LINE && (ccache_build)
		done
	fi
}
ccache_rebuild_main_tasker() {
	BSD_ENABLED_SBCS="$(ls -Im $BSD_SBC)"
	BSD_ENABLED_DISTS="$(ls -Im $BSD_DIST)"
	ccache_setup
	echo "... rebuilding all *** MISSING *** ccache [$BSD_CCACHE] accelerator dumps for $TOS!"
	echo "... *** skipping all pre-existing ccache dumps *** !!!"
	echo "... to enforce a new ccbuild, remove TARGET and CPU specific symbolic link within $BSD_CCACHE!"
	echo "... currently activated OS $TOS $SRC_CHECKOUT"
	echo "... currently activated SBCS for $TOS $BSD_ENABLED_SBCS"
	echo "... currently activated DISTs for $TOS $BSD_ENABLED_DISTS"
	BSD_ENABLED_SBCS="$(cat $BSD_SBC/.active)"
	BSD_ENABLED_DISTS="$(cat $BSD_DIST/.active)"
	for CUR in $BSD_ENABLED_SBCS; do
		CCSBC=$CUR
		(ccache_prep)
		(ccache_build_all_dists)
		(ccache_snap >> $LOGM)
	done
	beep
	unset BSD_REBUILD_CCACHE_MODE
	umount -f /usr/obj > /dev/null 2>&1
	echo "... ccache check/rebuild done!"
}
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
ccache_rebuild_check() {
	ccache_rebuild_main_tasker
}
####################################
###  EXTERNAL COMMAND INTERFACE  ###
####################################
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
case $1 in
rebuild) ccache_rebuild_main_tasker ;;
esac
###################################
