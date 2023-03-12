#!/bin/sh
####################################
### CONFIGURATION SETUP SECTION  ###
####################################
build_manpages_setup() {
	export MANTEMP=/tmp/man
	export DESTDIR=/tmp/man
	export PKG_REF=$BSD_PKG/fbsd.amd64.amd64.skylake
	export DTSFILE=$(date "+%Y%m%d")
	if [ ! $SRC_CHECKOUT ]; then export SRC_CHECKOUT="HEAD"; fi
	if [ ! -w /usr/obj ]; then mount -t tmpfs tmpfs /usr/obj; fi
}
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
build_manpages_prep() {
	sh /etc/.bsdconf rebuild_store
	rm -rf $MANTEMP
	for LOOP in man1 man2 man3 man3lua man4 man5 man6 man7 man8 man9 conf example; do
		mkdir -p $MANTEMP/usr/share/man/$LOOP
	done
}
build_manpages_src() {
	cd /tmp
	sh /etc/action/git.checkout freebsd
	cd freebsd
	for LOOP in 1 2 3 4 5 6 7 8 9; do
		find . -type f -name "*.$LOOP" -exec cp {} $MANTEMP/usr/share/man/man$LOOP \;
		find . -type f -name "*.$LOOP.in" -exec cp {} $MANTEMP/usr/share/man/man$LOOP \;
	done
	cd share/man
	export WITHOUT_MANCOMRPESS=true
	export WITHOUT_DOCCOMRPESS=true
	export MK_MANCOMPRESS=no
	export MK_DOCCOMPRESS=no
	export MK_TESTS=no
	export JFLAGS=8
	export MAN_ARCH=all
	$MAKE -j $JFLAGS install
	cd /tmp && rm -rf freebsd
}
build_manpages_pkg_action() {
	echo -n " $LINE "
	mkdir scratch.$LINE && cd scratch.$LINE
	tar -C scratch.$LINE -xf $PKG_REF/$LINE > /dev/null 2>&1
	for LOOP in 1 2 3 4 5 6 7 8 9 conf example; do
		find . -type f -name "*.$LOOP" -exec cp {} $MANTEMP/usr/share/man/man$LOOP \;
		find . -type f -name "*.$LOOP.in" -exec cp {} $MANTEMP/usr/share/man/man$LOOP \;
	done
	cd ..
	rm -rf scratch.$LINE
}
build_manpages_pkg() {
	PKGDIR=/tmp/pkg-man
	mkdir -p $PKGDIR && cd $PKGDIR
	LIST=$(ls -I $PKG_REF)
	for LINE in $LIST; do
		(build_manpages_pkg_action)
	done
	cd /tmp && rm -rf $PKGDIR
	rm -rf $MANTEMP/usr/share/man/manconf
}
build_manpages_workarounds() {
	# remove false posive / binaries
	find /tmp/man -perm 0755 -type f | xargs rm -f
}
build_manpages_index() {
	cd $MANTEMP/usr/share && makewhatis -a man && cd /tmp
}
build_manpages_external_prep() {
	export TDIR=/tmp/$T && mkdir -p $TDIR
	export FDIR=$MANTEMP/usr/share/man/$T && mkdir -p $FDIR
	cd /tmp && sh /etc/action/store git.checkout $T
}
build_manpages_tldr_pages() {
	export T=tldr-pages && build_manpages_external_prep
	cp -af $T/pages/linux/* $FDIR/
	cp -af $T/pages/common/* $FDIR/
	cd /tmp && rm -rf $TDIR
}
build_manpages_cheat_sheets() {
	export T=cheat-sheets && build_manpages_external_prep
	cp -af $T/* $FDIR/
	cd /tmp && rm -rf $TDIR
}
build_manpages_permissions() {
	chown -R 0:0 $MANTEMP/usr/share/*
	chmod -R u=rX,g=rX,o=rX $MANTEMP/usr/share
}
build_manpages_snapshot() {
	rm -rf $BSD_PKG/.store/all/manpages*
	sh /etc/goo/goo.fsdd --hard-link --fast-hash $MANTEMP
	IMG=$BSD_PKG/.store/all/manpages.$SRC_CHECKOUT.$DTSFILE.img.uzst
	XCMD="sh $BSD_ACTION/.create.img.sh $IMG $MANTEMP/usr/share/man ffs1 zstd manpages nofsck" && echo $XCMD && $XCMD
	cd $BSD_PKG && ln -fs ../.store/all/manpages.$SRC_CHECKOUT.$DTSFILE.img.uzst all/manpages
}
build_manpages_cleanup() {
	rm -rf $MANTEMP /tmp/current /tmp/GIT
}
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
rebuild_manpages() {
	echo "START_MAN build.manpages: $(date "+%Y%m%d-%H%M%S")"
	build_manpages_setup
	build_manpages_prep
	build_manpages_src &
	# build_manpages_pkg &
	build_manpages_tldr_pages &
	build_manpages_cheat_sheets &
	wait
	build_manpages_workarounds
	build_manpages_index
	build_manpages_permissions
	build_manpages_snapshot
	build_manpages_cleanup
	echo "END_MAN build.manpages: $(date "+%Y%m%d-%H%M%S")"
}
####################################
###  EXTERNAL COMMAND INTERFACE  ###
####################################
BSDlive llvm
. /etc/.bsdconf
sh /etc/action/store src
rebuild_manpages
###################################
