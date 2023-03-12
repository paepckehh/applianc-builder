#!/bin/sh
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
build_root_clean_generic() {
	LIST=$(cat $BSD_CONF/clean/.all)
	cd $ROOTFS
	for line in $LIST; do
		rm -rf $line > /dev/null 2>&1
	done
}
build_root_clean_dist_specific() {
	if [ -e $BSD_CONF/clean/$BSD_TARGET_DIST ]; then
		LIST=$(cat $BSD_CONF/clean/$BSD_TARGET_DIST)
		cd $ROOTFS
		for line in $LIST; do
			rm -rf $line > /dev/null 2>&1
		done
	fi
}
build_root_clean_feature_specific() {
	if [ "$EMBEDDED" == "true" ]; then
		LIST=$(cat $BSD_CONF/clean/.embedded)
		cd $ROOTFS
		for line in $LIST; do
			rm -rf $line > /dev/null 2>&1
		done
	fi
}
build_root_clean_create_privatelib() {
	cd $ROOTFS/usr/lib
	for LIB in zstd sqlite3 event1 ucl ssh fido2 cbor; do
		if [ -r libprivate$LIB.so ]; then ln -s libprivate$LIB.so lib$LIB.so; fi
	done
}
build_root_clean_create_struct() {
	cd $ROOTFS
	cp -af $BSD_CONF/etc .
	for CUR in tmp var root/.temp etc/ssl; do
		mkdir -p $CUR
	done
	cd $ROOTFS/usr
	for CUR in ccache sysroots store local src obj share/skel share/locale; do
		mkdir -p $CUR
	done
}
build_root_clean_create_dist_specific() {
	case $BSD_TARGET_DIST in
	bsrv)
		cd $ROOTFS/usr/include
		cp -f /usr/src/$SRC_CHECKOUT/sys/contrib/zstd/lib/*.h .
		ln -s private/event1/event.h event.h
		mkdir -p $ROOTFS/usr/libdata/pkgconfig && cd $ROOTFS/usr/libdata/pkgconfig
		cp -rf $ROOTFS/usr/lib/pkgconfig/* . > /dev/null 2>&1
		rm -rf $ROOTFS/usr/lib/pkgconfig > /dev/null 2>&1
		cp -f $BSD_CONF/patch/pkgconf/* . > /dev/null 2>&1
		;;
	esac
	cd $ROOTFS/usr/bin
	ln -fs ../libexec/flua lua
	cd $ROOTFS/usr/lib
	cd $ROOTFS/usr/bin
	if [ -n "$(strings -a openssl | grep 'LockSSL')" ]; then ln -fs openssl lockssl; fi
	mkdir -p $ROOTFS/usr/share && cd $ROOTFS/usr/share && rm -rf zoneinfo > /dev/null 2>&1
	ln -fs ../../etc/zoneinfo.nano zoneinfo
}
build_root_clean_postpkg_generic() {
	LIST=$(cat $BSD_CONF/clean/.all.postpkg)
	cd $ROOTFS
	for line in $LIST; do
		rm -rf $line > /dev/null 2>&1
	done
}
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
build_root_clean() {
	cd $ROOTFS
	echo "... start build.root.clean for $BSD_TARGET_DIST EMBEDDED: $EMBEDDED"
	(build_root_clean_generic)
	(build_root_clean_dist_specific)
	(build_root_clean_feature_specific)
	if [ "$WITH_BHYVE" = "true" ]; then (build_root_userboot); fi
	(build_root_clean_create_struct)
	(build_root_clean_create_privatelib)
	(build_root_clean_create_dist_specific)
	echo "... end build.root.clean!"
}
build_root_clean_postpkg() {
	cd $ROOTFS
	echo "... start build.root.clean POSTPKG for $BSD_TARGET_DIST EMBEDDED: $EMBEDDED"
	(build_root_clean_postpkg_generic)
	sync && echo "... end build.root.clean POSTPKG"

}
####################################
