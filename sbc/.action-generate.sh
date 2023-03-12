#!/bin/sh
if [ ! $BSD_CONF_VERSION ]; then . /etc/action/BSDconf; fi

action_rebuild_cc_targets() {
	LIST_CC_OS="fbsd linux"
	LIST_CC_TARGETS=$(ls -I $BSD_ARCH)
	LIST_DIR_CC_TARGETS=$BSD_SBC/.alias.cc
	rm -rf $LIST_DIR_CC_TARGETS
	mkdir -p $LIST_DIR_CC_TARGETS
	cd $LIST_DIR_CC_TARGETS
	for BUILD_OS in $LIST_CC_OS; do
		for BUILD_TARGET in $LIST_CC_TARGETS; do
			ln -fs $BSD_ARCH/$BUILD_TARGET $BUILD_OS.bsrv.$BUILD_TARGET
			echo "[done] rebuild CC TARGET $BUILD_TARGET"
		done
	done
}

action_rebuild_sbc_targets() {
	LIST_DIR_SBCS_TARGETS=$BSD_SBC/.alias
	cd $LIST_DIR_SBCS_TARGETS
	LIST_SBCS_DEFS="$(ls -I $BSD_SBC)"
	for SBC in $LIST_SBCS_DEFS; do
		. $BSD_SBC/$SBC
		ln -s ../$SBC $SBC
		for ALIAS in $BSD_TARGET_SBC_ALIAS_LIST; do
			ln -s ../$SBC $ALIAS
			echo "[done] rebuild SBC TARGET: $ALIAS"
		done
	done
}

action_rebuild_device_keys() {
	LIST_KEYS_FILES=$(ls -I $BSD_SBC/.device.keys)
	LIST_DIR_KEY_TARGETS=$BSD_SBC/.device.keys
	cd $LIST_DIR_KEY_TARGETS
	for KEYFILE in $LIST_KEY_FILES; do
		if [ -x /usr/bin/sponge ]; then
			cat $KEYFILE | sort -u | sponge $KEYFILE
		else
			cat $KEYFILE | sort -u > x && mv x $KEYFILE
		fi
		echo "[done] rebuild KEY TARGET: $KEYFILE"
	done
}
# main
(
	PREP=$BSD_SBC/.alias
	rm -rf $PREP
	mkdir -p $PREP
)
(action_rebuild_sbc_targets) &
(action_rebuild_cc_targets) &
(action_rebuild_device_keys) &
wait
sync && sync && sync
