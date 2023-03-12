#!/bin/sh
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
build_root_pkg() {
	echo "... start build_root_pkg"
	cd $ROOTFS
	if [ -e "$BSD_PKG/$TOS.$TARCH_TRIPLE/$BSD_TARGET_DIST" ] || [ -e "$BSD_PKG/all/$BSD_TARGET_DIST" ]; then
		BSD_DIST_PKG="$BSD_DIST_PKG $BSD_TARGET_DIST"
	fi
	for PKG in $BSD_DIST_PKG; do
		ARCH_AGNOSTIC="$BSD_PKG/all/$PKG"
		ARCH_SPECIFIC="$BSD_PKG/$TOS.$TARGET.$TARGETARCH.$TCPUTYPE/$PKG"
		if [ -r $ARCH_AGNOSTIC ]; then
			(tar -xf $ARCH_AGNOSTIC && echo "[done] ... install pkg $ARCH_AGNOSTIC") &
		fi
		if [ -r $ARCH_SPECIFIC ]; then
			(tar -xf $ARCH_SPECIFIC && echo "[done] ... install pkg $ARCH_SPECIFIC") &
		fi
	done
	wait
	if [ ! -e usr/bin/vim ] && [ -e /usr/bin/kilo ]; then (cd usr/bin && ln -fs kilo e); fi
	if [ $BSD_TARGET_DIST != "bsrv" ]; then
		rm -rf usr/include usr/libdata etc/netconfig
	fi
	echo "... end build_root_pkg"
}
build_root_base() {
	echo "... start build_root_base"
	cd $ROOTFS && mkdir -p home/root/.temp
	dd if=/dev/random of=entropy bs=1k count=1 status=none
	rm -rf usr/share/man usr/sbin/nologin > /dev/null 2>&1
	touch usr/sbin/nologin && chmod +x usr/sbin/nologin
	mkdir -p mnt/store/da0 mnt/store/da1 mnt/store/da2 mnt/store/da3 mnt/store/da4 mnt/store/da5 mnt/opti/cd0 mnt/opti/cd1 etc/wg
	mkdir -p mnt/gomod home/root/.hq/.unlocked .worker home/nobody/.hq/.unlocked etc/ssh etc/ssl home/root/.ssh usr/share/man proc
	if [ -r $BSD_DIST/.shared/add.alias.$BSD_TARGET_DIST ]; then . $BSD_DIST/.shared/add.alias.$BSD_TARGET_DIST; fi
	rm -rf root/.shrc root/.profile
	ln -fs /etc/.profile home/root/.profile
	ln -fs /etc/.profile home/nobody/.profile
	ln -fs /etc/.shrc home/root/.shrc
	ln -fs /etc/.shrc home/nobody/.shrc
	cd $ROOTFS/home/root && ln -fs .temp .tmp && ln -fs .temp .cache
	echo "... end build_root_base"
}
build_root_etc() {
	echo "... start build_root_etc"
	cd $ROOTFS/etc
	SALT=$(dd if=/dev/random status=none count=1 bs=512k | sha256 | openssl enc -A -base64 | cut -c 1-16)
	ROUNDS=$(dd if=/dev/random status=none count=1 bs=512k | sha256 | cksum | cut -c 1-7)
	echo "PWD DB HASH [uniq] SALT: $SALT [uniq] SHA512 ROUNDS:98$ROUNDS"
	sed -i '' -e "s/REPLACE_ME_SALTY/$SALT/g" login.conf
	sed -i '' -e "s/987654321/98$ROUNDS/g" login.conf
	cap_mkdb login.conf
	if [ -n "$BSD_REPLACE_ETC_NTP_CONF" ]; then echo "$BSD_REPLACE_ETC_NTP_CONF" > ntp/ntp.conf; fi
	if [ -n "$BSD_REPLACE_ETC_NTP_HOSTKEY" ]; then echo "$BSD_REPLACE_ETC_NTP_HOSTKEY" > ntp/host.key; fi
	if [ -n "$BSD_ETC_TTYS" ]; then
		echo "$BSD_ETC_TTYS" > ttys
	else
		rm -rf ttys
	fi
	if [ -r $BSD_DIST/.shared/add.rc.$BSD_TARGET_DIST ]; then . $BSD_DIST/.shared/add.rc.$BSD_TARGET_DIST; fi
	if [ -r $BSD_DIST/.shared/add.users.$BSD_TARGET_DIST ]; then . $BSD_DIST/.shared/add.users.$BSD_TARGET_DIST; fi
	echo "$BSD_ADD_ETC_RC_CONF" >> rc.conf
	echo "$BSD_ADD_ETC_GROUP" > group
	echo "$BSD_ADD_ETC_PASSWD" > passwd
	cp -f passwd master.passwd
	pwd_mkdb -v -i -d $ROOTFS/etc master.passwd
	echo "$BSD_SYSCTL" > $ROOTFS/etc/sysctl.conf
	echo "$BSD_SYSCTL_INFO" >> $ROOTFS/etc/sysctl.conf
	echo "... end build_root_etc"
}
build_root_etc_rc_d() {
	echo "... start build_root_etc_rc_d"
	cd $ROOTFS/etc
	mv -f rc.d rc.d.default && mkdir -p rc.d
	if [ -e rc.d.default/xx$BSD_TARGET_DIST ]; then BSD_DIST_RC="$BSD_DIST_RC xx$BSD_TARGET_DIST"; fi
	for RC in $BSD_DIST_RC; do (cp -af rc.d.default/$RC rc.d/); done
	if [ -n "$BSD_NIC" ]; then
		for RC in $BSD_DIST_RC_NIC; do (cp -af rc.d.default/$RC rc.d/); done
	fi
	if [ -n "$BSD_STO" ]; then
		for RC in $BSD_DIST_RC_STO; do (cp -af rc.d.default/$RC rc.d/); done
		unset WITHOUT_NMVE
		export WITH_NMVE=true
	fi
	if [ -n "$BSD_GFX" ]; then
		for RC in $BSD_DIST_RC_GFX; do (cp -af rc.d.default/$RC rc.d/); done
	fi
	if [ -n "$BSD_SND" ]; then
		for RC in $BSD_DIST_RC_SND; do (cp -af rc.d.default/$RC rc.d/); done
	fi
	if [ -n "$BSD_IOD" ]; then
		for RC in $BSD_DIST_RC_IOD; do (cp -af rc.d.default/$RC rc.d/); done
	fi
	if [ -n "$BSD_WNIC" ]; then
		for RC in $BSD_DIST_RC_WNIC; do (cp -af rc.d.default/$RC rc.d/); done
	fi
	rm -rf rc.d.default
	echo "... end build_root_etc_rc_d"
}
build_root_consolidate() {
	if [ "$NO_FSCHG" = "true" ]; then
		echo "... start build_root_consolidate [NO_FSCHG=true]"
		cd $ROOTFS
		mkdir -p usr/bin
		mv -f sbin/* usr/sbin/* usr/bin/
		rm -rf sbin usr/sbin
		ln -fs usr/bin sbin
		cd usr && ln -fs bin sbin
		cd $ROOTFS
		chflags -h 0 usr/lib/* lib/*
		MOVE_TARGETS="bin lib libexec"
		for CUR in $MOVE_TARGETS; do
			mv -f $CUR/* usr/$CUR/
			rm -rf $CUR
			ln -fs usr/$CUR $CUR
			sh /etc/goo/goo.fsdd --hard-link --replace-symlinks $ROOTFS/usr/$CUR
		done
	fi
	cd $ROOTFS
	TARGETS="root nobody"
	for CUR in $TARGETS; do
		mkdir -p $CUR home/$CUR usr/home/$CUR
		mv -f $CUR/* usr/home/$CUR/* home/$CUR/
		rm -rf $CUR usr/home/$CUR
	done
	ln -fs home/root root
	rm -rf usr/home
}
build_root_permissions() {
	echo "... start build_root_permissions"
	cd $ROOTFS
	TARGETS="bin lib libexec"
	for CUR in $TARGETS; do
		chflags noschg usr/$CUR/*
		chflags -R noschg usr/$CUR/
	done
	chmod -f -w .
	chmod -f -R u=rx,g=,o= home/root
	chmod -f -R u=rwx,g=rwx,o= home/root/.temp home/root/.hq home/root/.ssh
	chmod -f -h u=rwx,g=rwx,o= home/root/.cache home/root/.tmp
	mv etc/app etc/worker .
	chown -f -R 0:0 etc
	chown -f -R 65534:65534 home/nobody
	chmod -f u=r,g=,o= entropy
	chmod -f -R u=rX,g=,o= .bsdinfo
	chmod -f u=rx,g=rx,o=rx bin sbin lib libexec usr usr/bin usr/sbin usr/lib home
	chmod -f -R u=rx,g=rx,o=rx etc usr/libexec usr/libdata mnt usr/share usr/include .worker
	mv app worker etc/
	cd $ROOTFS/etc
	chmod -f -R u=rX,g=,o= ssh wg
	chmod -f -R u=rX,g=rX,o= app
	chmod -f -R u=rX,g=rX,o=rX ssl
	chmod -f u=rx,g=rx,o=rx app worker
	chmod -f u=r,g=r,o=r resolv.conf services termcap group hosts login* rc.info proto* zoneinfo.nano/* passwd pwd.db
	chmod -f u=rx,g=,o= network.subr rc.shutdown rc.subr rc rc.d/* rc.d pam.d devd.d defaults
	chmod -f u=r,g=,o= master.passwd spwd.db rc.conf pf.* sysctl* shells doas.conf devd.conf defaults/* pam.d/* devd.d/*
	chmod -f u=r,g=,o= syslog.conf sysctl.conf ttys nsswitch.conf newsyslog.conf gettytab rc.conf fstab devfs*
	sh /etc/goo/goo.fsdd --hard-link $ROOTFS
	cd $ROOTFS
	for CUR in $TARGETS; do
		chmod -f -R -w usr/$CUR
		chflags schg usr/$CUR/*
		chflags -R schg usr/$CUR/
	done
	find usr/lib -type f | xargs chmod 444
	echo "... end build_root_permissions"
}
build_root_userboot() {
	DST=$BSD_GIT/.bsd-boot/_userboot && mkdir -p $DST/defaults && mkdir -p $DST/kernel
	cd $ROOTFS && ln -fvs $DST boot
	if [ $UPDATE_USERBOOT ]; then
		mkdir -p $DST/defaults && mkdir -p $DST/kernel
		echo "### USERBOOT UPDATE"
		BSD_LOG_DIR=/tmp/.build.logs && mkdir -p $BSD_LOG_DIR
		MAKEDIR="/usr/src/$SRC_CHECKOUT/stand/lua"
		MAKECMD="$MAKE -j $JFLAG TARGET=$TARGET TARGET_ARCH=$TARGETARCH DESTDIR=$DST install"
		MAKELOG=$BSD_LOG_DIR/ok.make.lua.userboot.$TARCH_TRIPLE.$BSD_TARGET_SBC-$BSD_TARGET_DIST.$DTS
		echo "### USERBOOT LUA FILES INSTALL: $MAKEDIR $MAKECMD"
		cd $MAKEDIR && $MAKECMD > $MAKELOG
		cd $DST && mv boot/lua . && rm -rf boot
		SRC=/usr/obj/usr/src/HEAD/$TARCH_L1.$TARCH_L2/stand/userboot/userboot_$LOADER_INTERP/userboot_$LOADER_INTERP.so
		cp -fv $SRC userboot.so
		echo "### USERBOOT LOADER DEFAULTS"
		echo "### USERBOOT KERNEL"
		KBASE=$TOS.$BSD_TARGET_DIST.$TARCH_L1.$TARCH_L2.$TARCH_L3
		cd $DST && ln -fs $BSD_KERNEL/$KBASE kernel/kernel
		/usr/bin/dd if=/dev/random of=entropy bs=1k count=1 status=none
	fi
}
build_root_strip_deduplicate() {
	find $ROOTFS/usr/bin -type f -exec $STRIPBIN -s {} \; > /dev/null 2>&1
	sh /etc/goo/goo.fsdd --hard-link $ROOTFS
}
build_root_sign() {
	cd $ROOTFS && /usr/bin/hq s && chmod 400 .hq*.zst && chmod 500 .hq*.hqs
}
build_root_final_cleanup() {
	umount -f $ROOTFS && rm -rf $ROOTFS
}
build_rootfs_checkin() {
	mkdir -p $BSD_ROOTFS/.store
	cd $BSD_ROOTFS
	TARGETBASE=$TOS.$BSD_TARGET_DIST.$TARCH_TRIPLE
	TARGETNAME=$TARGETBASE.$(date "+%Y%m%d")
	rm -rf .store/$TARGETBASE.2*
	cp -avf $IMG .store/$TARGETNAME
	ln -fs .store/$TARGETNAME $TOS.$BSD_TARGET_DIST.$TARCH_TRIPLE
}
build_root_install_root() {
	. $BSD_ACTION/build.make.lib.sh
	. $BSD_ACTION/build.root.clean.lib.sh
	. $BSD_ACTION/build.crypto.lib.sh
	. $BSD_ACTION/build.bsdinfo.lib.sh
	cd $ROOTFS
	(make_installworld)
	(make_distribution)
	build_root_clean
	build_root_pkg
	build_root_clean_postpkg
	build_crypto &
	build_root_base &
	build_root_etc &
	build_root_etc_rc_d &
	build_root_bsdinfo &
	build_root_userboot &
	wait
	build_root_consolidate
	build_root_strip_deduplicate
	build_root_permissions
	build_root_sign
	wait
}
build_root_build_img() {
	IMG=$BOOTFS/boot/mdroot
	XCMD="sh $BSD_ACTION/.create.img.sh $IMG $ROOTFS ffs1 $BSD_MDROOT rootfs nofsck" && echo $XCMD && $XCMD
	wait
	case $BSD_TARGET_DIST in
	bsrv) build_rootfs_checkin ;;
	esac
	build_root_final_cleanup
}
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
build_root() {
	echo "START_BUILD_ROOT [$BOOTFS] [$ROOTFS] for [$BSD_TARGET_SBC] [$BSD_TARGET_DIST] [$(date "+%Y%m%d-%H%M%S")]"
	build_root_install_root
	build_root_build_img
	echo "END_BUILD_ROOT [$BOOTFS] [$ROOTFS] for [$BSD_TARGET_SBC] [$BSD_TARGET_DIST] [$(date "+%Y%m%d-%H%M%S")]"
}
####################################
