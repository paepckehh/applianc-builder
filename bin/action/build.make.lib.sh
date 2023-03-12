#!/bin/sh
####################################
### CONFIGURATION SETUP SECTION  ###
####################################
make_setup() {
	cd /usr/src/$SRC_CHECKOUT
	LLVM_CURRENT=llvm15
	. $BSD_ACTION/.buildenv.sh
	case $BSD_XTOOLCHAIN in
	llvm13 | llvm14 | llvm15 | llvm16) buildenv_activate_$BSD_XTOOLCHAIN ;;
	*) buildenv_activate_$LLVM_CURRENT ;;
	esac
	export COMMIT="$(cat .commit)"
	export gitup=$COMMIT
	export BRANCH_OVERRIDE="main-enhanced-"
	export NO_DEBUG=yes
	export NO_HISTORY=yes
	export NO_MODULES=yes
	export CFLAGS="$CFLAGS -pipe"
	export DESTDIR=$ROOTFS
	export MAKEOBJDIRPREFIX=/usr/obj
	export MALLOC_PRODUCTION=true
	export WITHOUT_MANCOMPRESS=true
	export LOADER_DEFAULT_INTERP=lua
	export __MAKE_CONF=/dev/null
	export SRC_CONF=/dev/null
	export SRCCONF=/dev/null
	export BSD_LOG_DIR=/tmp/.build.logs && mkdir -p $BSD_LOG_DIR
	export TMP=/tmp/.build.temp && export TMPDIR=$TMP && export TEMPDIR=$TMP && mkdir -p $TMP
	export MAKE_ACTION=$(echo $ACTION | cut -c 6-)
	export TARGET=$TARGET
	export TARGET_ARCH=$TARGETARCH
	export TARGET_CPUTYPE=$TCPUTYPE
	export KERNCONF=CORE
	export MAKE_CMD="$MAKE -j $JFLAG TARGET=$TARCH_L1 TARGET_ARCH=$TARCH_L2 CPUTYPE=$TARCH_L3 KERNCONF=CORE NO_MODULES=yes"
	export CFLAGS="$CFLAGS --ld-path=$LD"
	export LDFLAGS="$LDFLAGS --ld-path=$LD"
	unset DEBUG
}
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
make_check_log() {
	if [ $(tail -n 1 $LOG | sha224) = "cab8a6853704ea3697f2a90f99c21d04c085f7b8cd38a8cce2b79974" ] || [ $LOG_OK ]; then
		export BUILDOK=true
		rm -rf $LOG
		touch $BSD_LOG_DIR/ok.$CURRENT_LOG
	elif [ $(tail -n 2 $LOG | head -n 1 | sha224) = "cab8a6853704ea3697f2a90f99c21d04c085f7b8cd38a8cce2b79974" ] || [ $LOG_OK ]; then
		export BUILDOK=true
		rm -rf $LOG
		touch $BSD_LOG_DIR/ok.$CURRENT_LOG
	else
		unset BUILDOK
		mv $LOG $BSD_LOG_DIR/fail.$CURRENT_LOG
		echo "XXX FAIL $ACTION $TARGETARCH $KERNCONF $COMMIT FAIL XXX"
		beep ERR

	fi
}
make_check_recover() {
	if [ $AUTORECOVER ] && [ $AUTORECOVER_ALLOW ] && [ ! $BUILDOK ]; then
		echo "$ACTION $BSD_TARGET_SBC $BSD_TARGET_DIST $COMMIT FAILDED" > /dev/stdout && beep err
		exit # DEBUG EXIT (MANUAL ANALYSIS)
		while [ $LOOP -lt $AUTORECOVER_RANGE ] && [ ! $BUILDOK ]; do
			export LOOP=$((LOOP + 1))
			export COMMIT=$(cat $LAST | head -n $LOOP | tail -n 1 | cut -c 1-12)
			echo "... starting autorecover for $ACTION via $COMMIT temporary src tree checkout!"
			umount /usr/src/$SRC_CHECKOUT > /dev/null 2>&1
			umount /usr/src > /dev/null 2>&1
			sh $BSD_ACTION/build.src.rebuild.lib.sh "build_src_rebuild $SRC_CHECKOUT $COMMIT TEMPSRC"
			make_action
			make_check_log
		done
		umount /usr/src/$SRC_CHECKOUT > /dev/null 2>&1
		umount /usr/src > /dev/null 2>&1
	fi
}
make_ccache_setup_stats() {
	export STAT=$ACTION.$TARGET.$TARGETARCH.$TCPUTYPE.$BSD_TARGET_SBC-$BSD_TARGET_DIST.$(date "+%Y%m%d%H%M%S")
	export CC_LOG_SUMMARY=$BSD_LOG_DIR/ccache.summary.$STAT
	unset CCACHE_NOSTATS
	export CCACHE_STATS=true
	$CCACHE_BIN --zero-stats > $CC_LOG_SUMMARY
	$CCACHE_BIN --show-config | sort >> $CC_LOG_SUMMARY
}
make_ccache_setup_debug() {
	export CCACHE_STATSLOG=$BSD_LOG_DIR/ccache.statslog.$STAT
	export CCACHE_LOG_FILE=$BSD_LOG_DIR/ccache.log.$STAT
	make_ccache_setup_stats
}
make_ccache_snap_stats() {
	$CCACHE_BIN --verbose --show-stats >> $CC_LOG_SUMMARY
}
ake_ccache_snap_debug() {
	make_ccache_snap_stats
	$CCACHE_BIN --verbose --show-log-stats >> $CC_LOG_SUMMARY
	cat $CCACHE_STATSLOG | grep -B=1 direct_cache_miss | grep -v direct_cache_miss | sort > $BSD_LOG_DIR/ccache.fail.$STAT
}
make_action() {
	export CURRENT_LOG=$ACTION.$TARGET.$TARGETARCH.$TCPUTYPE.$BSD_TARGET_SBC-$BSD_TARGET_DIST.$MDTS
	export LOG=$BSD_LOG_DIR/$ACTION.$TARGET.$TARGETARCH.$TCPUTYPE.$BSD_TARGET_SBC-$BSD_TARGET_DIST.$MDTS
	cd /usr/src/$SRC_CHECKOUT
	if [ -n "$MAKE_FBSD_BIN" ]; then cd $MAKE_FBSD_BIN && export LOG="/dev/stdout" && echo "... custom make action dir $PWD"; fi
	if [ -n "$KERNEL_OUT" ]; then export DESTDIR=$BOOTFS; fi
	set > $BSD_LOG_DIR/env.$CURRENT_LOG
	echo "##########################################################################################################"
	echo "### CMD MAKE: $MAKE_CMD $MAKE_ACTION > $LOG"
	echo "### WITH CFLAGS: $CFLAGS"
	$MAKE_CMD $MAKE_ACTION > $LOG
}
make_info_start() {
	export MDTS=$(date "+%Y%m%d%H%M%S")
	echo "START_MAKE $ACTION  $MDTS"
	echo "... for TARGET=$TARCH_L1, TARGETARCH=$TARCH_L2, CPUTYPE=$TARCH_L3, KERNCONF=$KERNCONF"
	echo "... building for $TOS checkout $COMMIT using $JFLAG parallel make(s)!"
}
make_info_end() {
	echo "END_MAKE $ACTION $(date "+%Y%m%d-%H%M%S")"
}
make_main_debug() {
	make_setup
	make_ccache_setup_debug
	make_info_start
	make_action
	make_ccache_snap_debug
	make_check_log
	make_info_end
}
make_main_stats() {
	make_setup
	make_ccache_setup_stats
	make_info_start
	make_action
	make_ccache_snap_stats
	make_check_log
	make_info_end
}
make_main() {
	make_setup
	make_info_start
	make_action
	make_check_log
	make_info_end
}
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
make_buildkernel() {
	export ACTION="make.buildkernel"
	export AUTORECOVER_ALLOW=true
	export LOOP=1
	. $BSD_ACTION/build.kernconf.lib.sh
	kernconf_build
	make_main
}
make_installkernel() {
	CONF="$ROOTFS/.bsdinfo/KERNCONF"
	INFO="$CONF.INFO"
	KERNEL_IN="/usr/obj/usr/src/$SRC_CHECKOUT/$TARGET.$TARGETARCH/sys/CORE/kernel"
	KERNEL_DIR="$BOOTFS/boot/kernel" && mkdir -p $KERNEL_DIR
	KERNEL_OUT="$KERNEL_DIR/kernel"
	# mv $KERNEL_IN $KERNEL_OUT
	# export ACTION="make.installkernel" && make_main
	XCMD="$INSTALL -p -m 555 -o 0 -g 0 $KERNEL_IN $KERNEL_OUT"
	echo "$XCMD" && $XCMD
	echo "##############################################################################################" > $INFO
	echo "# KERNEL CHECKOUT          : $TOS $COMMIT " >> $INFO
	echo "# KERNEL COMPILER          : $($CC --version 2>&1 | head -n 1)" >> $INFO
	echo "# KERNEL KERNCONF [SHA256] : $(sha256 $CONF)" >> $INFO
	echo "# KERNEL BINARY   [SHA256] : $(sha256 $KERNEL_OUT)" >> $INFO
	echo "##############################################################################################" >> $INFO
	echo "# [USERLAND] BUILD ENV:" >> $INFO
	set | grep WITH >> $INFO
	echo "##############################################################################################" >> $INFO
}
make_storekernel() {
	case $BSD_TARGET_DIST in
	vsrv)
		case $TARGET in
		amd64)
			(
				echo "... kernel store checkin!"
				KERNEL_IN="/usr/obj/usr/src/$SRC_CHECKOUT/$TARGET.$TARGETARCH/sys/CORE/kernel"
				TARGETBASE=$TOS.$BSD_TARGET_DIST.$TARCH_L1.$TARCH_L2.$TARCH_L3
				TARGETNAME=$TARGETBASE.$(date "+%Y%m%d")
				mkdir -p $BSD_KERNEL/.store && cd $BSD_KERNEL
				rm -rf .store/$TARGETBASE.2*
				cp -af $KERNEL_IN .store/$TARGETNAME
				ln -fs .store/$TARGETNAME $TOS.$BSD_TARGET_DIST.$TARCH_L1.$TARCH_L2.$TARCH_L3
			)
			;;
		esac
		;;
	esac
}
make_buildworld() {
	export ACTION="make.buildworld"
	export AUTORECOVER_ALLOW=true
	export LOOP=1
	make_main
}
make_distribution() {
	export ACTION="make.distribution"
	export LOG_OK=true
	export LOOP=1
	make_main
}
make_installworld() {
	export ACTION="make.installworld"
	export LOOP=1
	make_main
}
make_packages() {
	export PKG_FORMAT=tar
	export ACTION="make.packages"
	export LOOP=1
	make_main
}
make_custom() {
	unset DEBUG
	export BSD_TARGET_DIST=bsrv
	export MK_PIE=no
	export MK_TESTS=no
	export MK_MAN=no
	export NO_DEBUG=yes
	export NO_SHARE=yes
	export NO_CLEAN=yes
	export NO_HISTORY=yes
	export NO_MODULES=yes
	export MAKEOBJDIRPREFIX=/usr/obj
	export WITHOUT_MAN=true
	export WITHOUT_MANCOMPRESS=true
	export __MAKE_CONF=/dev/null
	export SRC_CONF=/dev/null
	export SRCCONF=/dev/null
	export KERNCONF=$BSD_TARGET_SBC-$BSD_TARGET_DIST
	export BSD_LOG_DIR=/tmp/.build.logs && mkdir -p $BSD_LOG_DIR
	export TMP=/tmp/.build.temp && export TMPDIR=$TMP && export TEMPDIR=$TMP && mkdir -p $TMP
	export ACTION="make"
	export MAKE_ACTION=$(echo $ACTION | cut -c 6-)
	export MAKE_CMD="$MAKE -j $JFLAG TARGET=$TARGET TARGET_ARCH=$TARGETARCH CPUTYPE=$TCPUTYPE$CPUOPT KERNCONF=CORE NO_MODULES=yes"
	make_action
}
####################################
###  EXTERNAL COMMAND INTERFACE  ###
####################################
case $1 in
buildworld) make_buildworld ;;
buildkernel) make_buildkernel ;;
installworld) make_installworld ;;
installkernel) make_installkernel ;;
distribution) make_distribution ;;
packages) make_packages ;;
custom) make_custom ;;
esac
###################################
