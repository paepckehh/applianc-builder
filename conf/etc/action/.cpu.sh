#!/bin/sh
case $1 in
fast)
	case $ARCH_L3 in
	cortex-a7)
		pkill powerd
		sysctl dev.cpu.0.freq=900
		;;
	x86-64-v2 | x86-64-v3)
		cpu=0
		cpus=$(sysctl -n hw.ncpu)
		while [ "$cpu" -lt "$cpus" ]; do
			sysctl dev.hwpstate_intel.$cpu.epp=0
			cpu=$((cpu + 1))
		done
		;;
	*) echo "[cpu] target plattform [$ARCH_L3] not supported, please add!" ;;
	esac
	;;
normal)
	case $ARCH_L3 in
	cortex-a7)
		service restart powerdxx
		;;
	x86-64-v2 | x86-64-v3)
		cpu=0
		cpus=$(sysctl -n hw.ncpu)
		while [ "$cpu" -lt "$cpus" ]; do
			sysctl dev.hwpstate_intel.$cpu.epp=50
			cpu=$((cpu + 1))
		done
		;;
	*) echo "[cpu] target plattform [$ARCH_L3] not supported, please add!" ;;
	esac
	;;
eco)
	case $ARCH_L3 in
	cortex-a7)
		pkill powerd
		sysctl dev.cpu.0.freq=600
		;;
	x86-64-v2 | x86-64-v3)
		cpu=0
		cpus=$(sysctl -n hw.ncpu)
		while [ "$cpu" -lt "$cpus" ]; do
			sysctl dev.hwpstate_intel.$cpu.epp=100
			cpu=$((cpu + 1))
		done
		;;
	*) echo "[cpu] target plattform [$ARCH_L3] not supported, please add!" ;;
	esac
	;;
*) echo "please choose cpu <fast|eco|normal>" ;;
esac
