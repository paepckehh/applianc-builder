#!/bin/sh
####################################
### CONFIGURATION SETUP SECTION  ###
####################################
src_rebuild_setup() {
	/etc/action/BSDlive llvm
	. /etc/.bsdconf
	. $BSD_ACTION/.buildlock.fbsd.sh
	# export CHECKOUT_FBSD_LUA="refs/remotes/origin/master"
	# export CHECKOUT_FBSD_XZ="refs/remotes/origin/master"
	# export CHECKOUT_FBSD_LIBARCHIVE="refs/remotes/origin/master"
	# export CHECKOUT_FBSD_LIBEVENT="refs/remotes/origin/master"
	# export CHECKOUT_FBSD_ZSTD="v1.5.0"
	# export CHECKOUT_FBSD_ZSTD="refs/remotes/origin/dev"
	# export CHECKOUT_FBSD_OPENSSL="refs/remotes/origin/OpenSSL_1_1_1-stable"
	# export CHECKOUT_FBSD_OPENSSL="refs/tags/openssl-3.0.0-beta2"
	# export CHECKOUT_FBSD_LLVM="refs/remotes/origin/vendor/llvm-project/release-13.x"
	# export CHECKOUT_FBSD_LLVM="vendor/llvm-project/llvmorg-13.0.0-rc3-8-g08642a395f23"
	if [ "$CHECKOUT_FBSD" = "" ]; then export CHECKOUT_FBSD="HEAD"; fi
	if [ "$CHECKOUT_FBSD_ZSTD" = "" ]; then export CHECKOUT_FBSD_ZSTD="HEAD"; fi
	if [ "$CHECKOUT_FBSD_OPENSSL" = "" ]; then export CHECKOUT_FBSD_OPENSSL="HEAD"; fi
	if [ ! $TARGETOS ]; then export TOS=fbsd && export TARGETOS=freebsd; fi
	if [ ! $SRC_CHECKOUT ]; then export SRC_CHECKOUT=HEAD; fi
	if [ ! -w /usr/obj ]; then mount -t tmpfs tmpfs /usr/obj; fi
	export TMP=/tmp/.build.temp && TMPDIR=$TMP && mkdir -p $TMP
	export LOGSRC=/tmp/.src.patchlog && mkdir -p $LOGSRC
	export REPO=$BSD_GIT/.repo/$TARGETOS/.git
	# export CHECKOUT_FBSD="366da717deda"
}
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
fbsd_custom_build_dtb() {
	DTB_SRC=$BSD_BOOT/VENDOR/rpi-dts
	echo "... check-in $DTS_SRC *** VENDOR *** specific dts/dtsi/dtbo files [linux main is a laggy/mess ]!"
	cd /usr/src/$SRC_CHECKOUT/sys/dts
	cp -rf $DTB_SRC/* vendor
	# DTB_SRC=$BSD_BOOT/VENDOR/apple-dts
	# cp -rf $DTB_SRC/* vendor
	echo "... rebuild [rebrand] dts files as valid freebsd versions [needs patch 400/401]"
	cd /usr/src/$SRC_CHECKOUT/sys/dts && make -Bk
}
fbsd_auto_patch() {
	echo ""
	echo "################################"
	echo "... quick auto patches!"
	PATCH_DIR=$BSD_CONF/patch && mkdir -p $PATCH_DIR/.done
	PLOG=$LOGSRC/patch.log && rm -rf $PLOG && touch $PLOG
	cd /usr/src/$SRC_CHECKOUT
	ls -I $PATCH_DIR | sort | while read PATCH; do
		echo $PATCH
		echo "" >> $PLOG
		echo "##############" >> $PLOG
		echo $PATCH >> $PLOG
		head -n 3 $PATCH_DIR/$PATCH
		head -n 3 $PATCH_DIR/$PATCH >> $PLOG
		patch -V none --batch --reject-file $LOGSRC/patch.fail.$PATCH -i $PATCH_DIR/$PATCH >> $PLOG
	done
	cp $PLOG /usr/src/$SRC_CHECKOUT/.patch.log
}
fbsd_auto_patch_rollback() {
	echo ""
	echo "################################"
	echo "... quick auto rollback patches!"
	PATCH_DIR=$BSD_CONF/patch.auto.rollback && mkdir -p $PATCH_DIR/.done
	PLOG=$LOGSRC/auto.patch.rollback.log && rm -rf $PLOG && touch $PLOG
	cd /usr/src/$SRC_CHECKOUT
	ls -I $PATCH_DIR | sort | while read PATCH; do
		echo $PATCH
		echo "" >> $PLOG
		echo "##############" >> $PLOG
		echo $PATCH >> $PLOG
		head -n 3 $PATCH_DIR/$PATCH
		head -n 3 $PATCH_DIR/$PATCH >> $PLOG
		patch -V none --batch -R --reject-file $LOGSRC/auto.patch.rollback.fail.$PATCH -i $PATCH_DIR/$PATCH >> $PLOG
	done
	cp $PLOG /usr/src/$SRC_CHECKOUT/.checkout.auto.patch.rollback.log
}
fbsd_kernconf_dynalinks() {
	for ARCH in arm arm64 amd64; do
		cd /usr/src/$SRC_CHECKOUT/sys/$ARCH/conf
		ln -fs /tmp/.build.temp/CORE CORE
	done
	echo "[done] ... rebuild dynamic KERNCONF logic!"
}
fbsd_cleanup_remove_blobs() {
	cd /usr/src/$SRC_CHECKOUT
	find . -type f | grep "\.ucode$" | xargs rm -f > /dev/null 2>&1
	find . -type f | grep "\.uu" | grep -v tabset | xargs rm
	find . -type f | grep "\.pkg$" | xargs rm -f > /dev/null 2>&1
	find . -type f | grep "\.o$" | xargs rm -f > /dev/null 2>&1
	find . -type f | grep -i "\.md$" | xargs rm -f > /dev/null 2>&1
	find . -type f | egrep '\.1$|\.2$|\.3$|\.4$|\.5$|\.6$|\.7$|\.8$|\.9$' | xargs rm -f > /dev/null 2>&1
}
fbsd_fix_src_ro_rule_offender() {
	# keep it ... it breaks from time to time again
	cd /usr/src/$SRC_CHECKOUT/stand/libsa
	ln -s ../common/*.h .
}
cleanup_env() {
	cd /tmp && sh /etc/action/store drop.src > /dev/null 2>&1
	umount -f /usr/src/$SRC_CHECKOUT > /dev/null 2>&1
	umount -f /usr/src > /dev/null 2>&1
	mdconfig -d -u $BSD_MD_SRC -o force > /dev/null 2>&1
}
fbsd_update_lua() {
	cd /usr/src/$SRC_CHECKOUT/contrib/lua
	rm -rf src
	/etc/action/git.checkout lua $CHECKOUT_FBSD_LUA patchclean
	mv lua src
}
fbsd_update_libevent() {
	cd /usr/src/$SRC_CHECKOUT/contrib
	mv libevent libevent.fsbsd
	/etc/action/git.checkout libevent2 $CHECKOUT_FBSD_LIBEVENT patchclean
	mv libevent2 lib/event
	cd libevent
	while read LINE; do (rm -rf libevent/$LINE); done < ../libevent.fbsd/FREEBSD-Xlist
	cd ..
	rm -rf libevent.fbsd
}
fbsd_update_xz() {
	cd /usr/src/$SRC_CHECKOUT/contrib
	mv xz xz.fbsd
	/etc/action/git.checkout xz $CHECKOUT_FBSD_XZ patchclean
	cd xz
	while read LINE; do (rm -rf xz/$LINE); done < ../xz.fbsd/FREEBSD-Xlist
	cd ..
	rm -rf xz.fbsd
}
fbsd_update_libarchive() {
	cd /usr/src/$SRC_CHECKOUT/contrib
	mv libarchive libarchive.fbsd
	/etc/action/git.checkout libarchive $CHECKOUT_FBSD_LIBARCHIVE patchclean
	cd libarchive
	while read LINE; do (rm -rf libarchive/$LINE); done < ../libarchive.fbsd/FREEBSD-Xlist
	rm -rf libarchive.fbsd
}
fbsd_update_zstd() {
	# UPSTREAM / via $ENHANCED patchset:
	# -> needs usr.bin/zstd/Makefile patch and some api changes within sys/kern/subr_compressor.c [opt mkuzip patches]
	cd /usr/src/$SRC_CHECKOUT/sys/contrib
	mv zstd zstd.fbsd
	/etc/action/git.checkout zstd $CHECKOUT_FBSD_ZSTD patchclean
	cp zstd/lib/common/xxhash* zstd/programs/
	cp -rf zstd.fbsd/lib/freebsd zstd/lib
	cd zstd
	while read LINE; do (rm -rf zstd/$LINE); done < ../zstd.fbsd/FREEBSD-Xlist
	cd ..
	rm -rf zstd.fbsd
}
fbsd_update_openssl() {
	# update openssl and convert it via $ENHANCED patchset openssl to lockssl
	cd /usr/src/$SRC_CHECKOUT/crypto
	mv openssl openssl.fbsd
	/etc/action/git.checkout openssl $CHECKOUT_FBSD_OPENSSL patchclean
	# re-config / cleanup
	cp -avf openssl.fbsd/apps/progs.h openssl/apps/
	cp -avf openssl.fbsd/include/crypto/dso_conf.h openssl/include/crypto/
	cp -avf openssl.fbsd/include/crypto/bn_conf.h openssl/include/crypto/
	# patch shlib and version to align fbsd logic
	sed -i '' -e "s/xx XXX xxxx/LockSSL ( RELEASE:$(cat openssl/RELEASE) ) ( COMMIT:$(cat openssl/.commit) )  via OpenSSL_1_1_1-stable /g" openssl/include/openssl/opensslv.h
	sed -i '' -e "s/\"OpenSSL /\"LockSSL ( RELEASE:$(cat openssl/RELEASE) ) ( COMMIT:$(cat openssl/.commit) ) via OpenSSL_1_1_1-stable /g" openssl/include/openssl/opensslv.h
	sed -i '' -e 's/"1.1.1"/"111"/g' openssl/include/openssl/opensslv.h
	sed -i '' -e 's/"1.1"/"111"/g' openssl/include/openssl/opensslv.h
	# document after custom diff
	# diff -ur openssl.fbsd openssl > $LOGSRC/src.rebuild.openssl.after-custom-patchset.diff
	rm -rf openssl.fbsd
}
prep_src() {
	PLOG=$LOGSRC/patch.enhanced.log && echo "#!/bin/sh" > $PLOG
	(cd $BSD_DEV/enhanced && make rebuild clean)
	echo "### GIT REPO MODE detected - starting git HEAD/repo checkout!"
	echo "#### BRANCH: $SRC_CHECKOUT #####"
	echo "... check repo status [ gc --auto ]"
	su gitclient -c "git -C $REPO gc --auto"
	if [ -e refs/heads/main ] || [ -e refs/heads/master ]; then
		echo "... repo recently updated without successful gc - need to run full gc cleanup now!"
		su gitclient -c "git -C $REPO gc --auto"
	fi
	echo "CHECKOUT $CHECKOUT_FBSD"
	echo "REPO $CHECKOUT_FBSD @ $REPO --> [ $TARGETOS ]"
	echo "#####################################################################################"
	echo "##### UNSECURE GIT CHECKOUT MODE ####################################################"
	echo "#####################################################################################"
	echo "... please think twice before you use/build/run or SIGN anything from this checkout!#"
	echo ""
	echo "### LAST CHECKOUT COMMIT DETAILS:"
	su gitclient -c "git -C $REPO show $CHECKOUT_FBSD | head -n 10"
	echo ""
	echo "### LAST 20 COMMITS OVERVIEW [ ... used as feed for auto-rollback during build-fails! ]"
	su gitclient -c "git -C $REPO log -n 20 --format=oneline $CHECKOUT_FBSD"
	echo ""
	mkdir -p /usr/src > /dev/null 2>&1
	mount -t tmpfs tmpfs /usr/src
	cd /usr/src
	/etc/action/git.checkout freebsd $CHECKOUT_FBSD patchclean >> $PLOG
	mv freebsd $SRC_CHECKOUT && cd $SRC_CHECKOUT
	touch .enhanced
	su gitclient -c "git -C $REPO log -n 100 --format=oneline --first-parent $CHECKOUT_FBSD > .checkout.last100.fbsd"
	su gitclient -c "git -C $REPO log -n 100 --format=oneline --first-parent $CHECKOUT_FBSD | cut -c 1-40 > .checkout.last100.fbsd.list"
	cat $REPO/config > .git.conf.current.config
	cat $REPO/HEAD > .git.conf.current.HEAD
	head -n 10 $REPO/packed-refs > .git.conf.refs
	echo ""
}
build_src_snapshot_store() {
	$FSDD_CMD .
	C_ONLY=true sh $BSD_ACTION/.code.compact.sh /usr/src/$SRC_CHECKOUT libedit rc.d
	BASE=$BSD_PKG/.store/all/fbsd.$SRC_CHECKOUT && IMG=$BASE.$(date "+%Y%m%d").img.uzst && rm -rf $BASE.*
	XCMD="sh $BSD_ACTION/.create.img.sh $IMG /usr/src/$SRC_CHECKOUT ffs1 zstd14 src nofsck" && echo $XCMD && $XCMD
	cd $BSD_PKG/all && ln -fs $IMG fbsd.$SRC_CHECKOUT
	umount -f /usr/src/$SRC_CHECKOUT /usr/src > /dev/null 2>&1
}
build_src_bsdlock_fetch() {
	OSSL_STABLE="OpenSSL_1_1_1t"
	FBSD_HASH=$(su gitclient -c "git -C $GIT/.repo/freebsd show" | head -n 1 | cut -c 8-23)
	ZSTD_HASH=$(su gitclient -c "git -C $GIT/.repo/zstd show" | head -n 1 | cut -c 8-23)
	FBSD="export CHECKOUT_FBSD=$FBSD_HASH"
	ZSTD="export CHECKOUT_FBSD_ZSTD=$ZSTD_HASH"
	OSSL="export CHECKOUT_FBSD_OPENSSL=$OSSL_STABLE"
	LIST="HEAD INFO FBSD ZSTD OSSL"
}

build_src_bsdlock_out() {
	echo $HEAD > $FILE
	echo $INFO >> $FILE
	echo $FBSD >> $FILE
	echo $ZSTD >> $FILE
	echo $OSSL >> $FILE
	chmod 755 $FILE
}
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
#!/bin/sh
build_src_lock() {
	DATE=$(date "+%Y%m%d")
	FILE=$BSD_ACTION/.buildlock.fbsd.sh
	HEAD="#!/bin/sh"
	INFO="### ( $DATE ) ### DO NOT EDIT ### auto-generated file by buildlock ###"
	build_src_bsdlock_fetch
	build_src_bsdlock_out
	cat $FILE
}
build_src_rebuild() {
	if [ "$DISTRIBUTION" != "bsrv" ]; then echo "... src imgage rebuild needs bsrv build tool set! EXIT!" && exit; fi
	src_rebuild_setup
	cleanup_env
	echo "START: rebuild $TARGETOS src img for $SRC_CHECKOUT!"
	prep_src
	case $TARGETOS in
	freebsd* | hardenendBSD* | hbsd* | cheriBSD*)
		(fbsd_auto_patch)
		(fbsd_auto_patch_rollback)
		(fbsd_cleanup_remove_blobs) &
		# (fbsd_custom_build_dtb) &
		(fbsd_kernconf_dynalinks) &
		wait
		if [ "$CHECKOUT_FBSD_OPENSSL" != "" ]; then (fbsd_update_openssl); fi
		# if [ "$CHECKOUT_FBSD_ZSTD" != "" ]; then (fbsd_update_zstd); fi
		if [ "$CHECKOUT_FBSD_LLVM" != "" ]; then (fbsd_update_llvm); fi
		if [ "$CHECKOUT_FBSD_LIBARCHIVE" != "" ]; then (fbsd_update_libarchive); fi
		if [ "$CHECKOUT_FBSD_LIBEVENT" != "" ]; then (fbsd_update_libevent); fi
		if [ "$CHECKOUT_FBSD_XZ" != "" ]; then (fbsd_update_xz); fi
		if [ "$CHECKOUT_FBSD_LUA" != "" ]; then (fbsd_update_lua); fi
		wait
		cd /usr/src/$SRC_CHECKOUT
		find . -type d -name test | egrep -v 'spk|bin\/test|mtest|make' | xargs rm -rf
		egrep 'fail|offset' /tmp/.src.patchlog/* | grep -v 'set\.diff'
		sync && sync && sync
		;;
	esac
	wait
	(cd /usr/src/$SRC_CHECKOUT && /usr/bin/hq s)
	if [ $TEMPSRC ]; then
		echo "... tempfs src tree /usr/src/$SRC_CHECKOUT available now!"
	else
		echo "... making image snapshot amd check into store!"
		build_src_snapshot_store
		cleanup_env
	fi
	echo "END: rebuild src img!"
	beep
}
####################################
###  EXTERNAL COMMAND INTERFACE  ###
####################################
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
if [ $2 ]; then export SRC_CHECKOUT=$2; fi
if [ $3 ]; then export GTAGTEMP=$3; fi
if [ $4 ]; then export TEMPSRC=true; fi
case $1 in
build*) build_src_rebuild ;;
lock*) build_src_lock ;;
esac
###################################
