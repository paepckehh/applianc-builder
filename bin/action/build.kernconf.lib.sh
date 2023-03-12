#!/bin/sh
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
kernconf_build() {
	. $BSD_SBC/$BSD_TARGET_SBC
	. $BSD_DIST/$BSD_TARGET_DIST
	TDIR="$ROOTFS/.bsdinfo" && T="$TDIR/KERNCONF" && mkdir -p $TDIR && touch $T
	mkdir -p /tmp/.build.temp && ln -fs $T /tmp/.build.temp/CORE
	echo "#!/bin/sh" > $T
	echo "## auto-generated DYNAMIC KERNCONF $BSD_TARGET_SBC $BSD_TARGET_DIST - do not edit - $(date "+%Y-%m-%d %H:%M:%S")" >> $T
	echo "ident $BSD_TARGET_SBC-$BSD_TARGET_DIST" >> $T
	if [ -n "$BSD_KERNCONF_MACHINE" ]; then echo "machine $BSD_KERNCONF_MACHINE" >> $T; fi
	if [ -n "$BSD_KERNCONF_CPU" ]; then for X in $BSD_KERNCONF_CPU; do (echo "cpu $X" >> $T); done; fi
	if [ -n "$BSD_KERNCONF_OPTIONS" ]; then for X in $BSD_KERNCONF_OPTIONS; do (echo "options $X" >> $T); done; fi
	if [ -n "$BSD_KERNCONF_NOOPTIONS" ]; then for X in $BSD_KERNCONF_NOOPTIONS; do (echo "nooptions $X" >> $T); done; fi
	if [ -n "$BSD_KERNCONF_DEVICE" ]; then for X in $BSD_KERNCONF_DEVICE; do (echo "device $X" >> $T); done; fi
	if [ -n "$BSD_KERNCONF_NODEVICE" ]; then for X in $BSD_KERNCONF_NODEVICE; do (echo "nodevice $X" >> $T); done; fi
	if [ -n "$BSD_KERNCONF_FILES" ]; then for X in $BSD_KERNCONF_FILES; do (echo "files \"$X\"" >> $T); done; fi
	if [ -n "$BSD_NIC" ]; then
		if [ -n "$BSD_KERNCONF_DEVICE_NIC" ]; then for X in $BSD_KERNCONF_DEVICE_NIC; do (echo "device $X" >> $T); done; fi
		if [ -n "$BSD_KERNCONF_OPTIONS_NIC" ]; then for X in $BSD_KERNCONF_OPTIONS_NIC; do (echo "options $X" >> $T); done; fi
	fi
	if [ -n "$BSD_WNIC" ]; then
		if [ -n "$BSD_KERNCONF_DEVICE_WNIC" ]; then for X in $BSD_KERNCONF_DEVICE_WNIC; do (echo "device $X" >> $T); done; fi
		if [ -n "$BSD_KERNCONF_OPTIONS_WNIC" ]; then
			for X in $BSD_KERNCONF_OPTIONS_WNIC; do (echo "options $X" >> $T); done
		fi
	fi
	if [ -n "$BSD_STO" ]; then
		if [ -n "$BSD_KERNCONF_DEVICE_STO" ]; then for X in $BSD_KERNCONF_DEVICE_STO; do (echo "device $X" >> $T); done; fi
		if [ -n "$BSD_KERNCONF_OPTIONS_STO" ]; then for X in $BSD_KERNCONF_OPTIONS_STO; do (echo "options $X" >> $T); done; fi
	fi
	if [ -n "$BSD_GFX" ]; then
		if [ -n "$BSD_KERNCONF_DEVICE_GFX" ]; then for X in $BSD_KERNCONF_DEVICE_GFX; do (echo "device $X" >> $T); done; fi
		if [ -n "$BSD_KERNCONF_OPTIONS_GFX" ]; then for X in $BSD_KERNCONF_OPTIONS_GFX; do (echo "options $X" >> $T); done; fi
	fi
	if [ -n "$BSD_SND" ]; then
		if [ -n "$BSD_KERNCONF_DEVICE_SND" ]; then
			BSD_KERNCONF_DEVICE_SND="$BSD_KERNCONF_DEVICE_SND sound"
			for X in $BSD_KERNCONF_DEVICE_SND; do (echo "device $X" | sort | uniq >> $T); done
		fi
		if [ -n "$BSD_KERNCONF_OPTIONS_SND" ]; then for X in $BSD_KERNCONF_OPTIONS_SND; do (echo "options $X" >> $T); done; fi
	fi
	if [ -n "$BSD_IOD" ]; then
		if [ -n "$BSD_KERNCONF_DEVICE_IOD" ]; then for X in $BSD_KERNCONF_DEVICE_IOD; do (echo "device $X" >> $T); done; fi
		if [ -n "$BSD_KERNCONF_OPTIONS_IOD" ]; then for X in $BSD_KERNCONF_OPTIONS_IOD; do (echo "options $X" >> $T); done; fi
	fi
	if [ -n "$BSD_KERNCONF_MAKEOPTIONS_DEBUG" ]; then
		echo "makeoptions DEBUG=\"$BSD_KERNCONF_MAKEOPTIONS_DEBUG\"" >> $T
	fi
	if [ -n "$BSD_KERNCONF_MAKEOPTIONS_WITH_CTF" ]; then
		echo "makeoptions WITH_CTF=\"$BSD_KERNCONF_MAKEOPTIONS_WITH_CTF\"" >> $T
	fi
	if [ -n "$BSD_KERNCONF_MAKEOPTIONS_CONF_CFLAGS" ]; then
		echo "makeoptions CONF_CFLAGS=\"$BSD_KERNCONF_MAKEOPTIONS_CONF_CFLAGS\"" >> $T
	fi
	if [ -n "$BSD_KERNCONF_MAKEOPTIONS_MODULES_EXTRA" ]; then
		echo "makeoptions MODULES_EXTRA=\"$BSD_KERNCONF_MAKEOPTIONS_MODULES_EXTRA\"" >> $T
	else
		echo 'makeoptions MODULES_EXTRA=""' >> $T
	fi
	cat $T | sort -u | sponge $T
	cp $T /tmp/.build.logs/kernconf.$BSD_TARGET_SBC.$BSD_TARGET_DIST
	if [ $BSD_KERNCONF_MAKEOPTIONS_CONF_CFLAGS ]; then export CFLAGS=$BSD_KERNCONF_MAKEOPTIONS_CONF_CFLAGS; fi
	echo "[done] rebuild dynamic kernconf for $T"
}
