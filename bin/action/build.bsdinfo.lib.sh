#!/bin/sh
build_root_bsdinfo() {
	echo "... start build_root_info"
	cd $ROOTFS
	mkdir -p $ROOTFS/.bsdinfo && cd $ROOTFS/.bsdinfo
	RCINFO=$ROOTFS/etc/rc.info
	COMMIT="$(cat /usr/src/$SRC_CHECKOUT/.commit)"
	echo "#!/bin/sh
export ARCH_OS=freebsd
export ARCH=$TARGETARCH
export ARCH_L1=$TARCH_L1
export ARCH_L2=$TARCH_L2
export ARCH_L3=$TARCH_L3
export ARCH_TRIPLE=$TARCH_L1.$TARCH_L2.$TARCH_L3
export X86_64_LEVEL=$TX86_64_LEVEL
export SBC=$BSD_TARGET_SBC
export SOC=$BSD_TARGET_SOC
export DIST=$BSD_TARGET_DIST
export DISTRIBUTION=$BSD_TARGET_DIST
export COMMIT=$COMMIT" > $RCINFO
	echo $TARGETARCH > ARCH
	echo $TARCH_L1 > ARCH_L1
	echo $TARCH_L2 > ARCH_L2
	echo $TARCH_L3 > ARCH_L3
	echo $TARCH_L4 > ARCH_L4
	echo $TARCH_L1.$TARCH_L2.$TARCH_L3 > ARCH_TRIPLE
	echo $TARCH_L1.$TARCH_L2.$TARCH_L3.$TARCH_L4 > ARCH_QUAD
	if [ "$TARGETARCH" = "amd64" ]; then echo $TX86_64_LEVEL > X86_64_LEVEL; fi
	echo $COMMIT > COMMIT
	echo $BSD_TARGET_SBC > SBC
	echo $BSD_TARGET_SOC > SOC
	echo $BSD_TARGET_DIST > DIST
	echo $BSD_TARGET_DIST > DISTRIBUTION
	if [ -n "$BSD_NIC" ]; then
		if [ -z $NIC_PRIMARY ]; then NIC_PRIMARY="ue0"; fi
		if [ -z $NIC_PRIMARY_IP ]; then NIC_PRIMARY_IP="10.10.10.10"; fi
		echo $NIC_PRIMARY > NIC_PRIMARY
		echo $NIC_PRIMARY_IP > NIC_PRIMARY_IP
		echo "export NIC_PRIMARY=$NIC_PRIMARY" >> $RCINFO
		echo "export NIC_PRIMARY_IP=$NIC_PRIMARY_IP" >> $RCINFO
		echo "export ifconfig_$NIC_PRIMARY=\"inet $NIC_PRIMARY_IP netmask 0xffffff00\"" >> $RCINFO
		if [ -n "$NIC_SECONDARY" ]; then
			echo $NIC_SECONDARY > NIC_SECONDARY
			echo $NIC_SECONDARY_IP > NIC_SECONDARY_IP
			echo "export NIC_SECONDARY=$NIC_SECONDARY" >> $RCINCO
			echo "export NIC_SECONDARY_IP=$NIC_SECONDARY_IP" >> $RCINFO
			echo "export ifconfig_$NIC_SECONDARY=\"inet $NIC_SECONDARY_IP netmask 0xffffff00\"" >> $RCINFO
		fi
	fi
	echo "export hostname=\"$BSD_TARGET_SBC-$BSD_TARGET_DIST\"" >> $RCINFO
	chmod 444 * $ROOTFS/.bsdinfo/*
	chown 0:0 * $ROOTFS/.bsdinfo/*
	echo "... end build_root_info"
}
