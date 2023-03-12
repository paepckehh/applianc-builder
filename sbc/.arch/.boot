#!/bin/sh
case $SOC in
vh*)
	export BOOT_FBSD_IMG=vhdf
	;;
q*)
	export BOOT_FBSD_IMG=qcow2
	;;
*)
	export BOOT_FBSD_IMG=raw
	;;
esac
