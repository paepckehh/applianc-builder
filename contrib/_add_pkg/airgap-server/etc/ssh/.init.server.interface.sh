#!/bin/sh
. /etc/ssh/.init.server.keys.interface
SSH_SERVER="$(ls -I /etc/ssh | grep server)"

sshd_reset() {
	echo "[ssh] [srv] [interface] reset action triggered!" | logger
	for SERVER in $SSH_SERVER; do
		sh /etc/ssh/$SERVER/.init.sh reset
	done
	if [ -x /usr/bin/wg ]; then
		/usr/bin/ifconfig wg0 down > /dev/null 2>&1
		/usr/bin/ifconfig wg0 inet delete > /dev/null 2>&1
		/usr/bin/ifconfig wg0 destroy > /dev/null 2>&1
	fi
	/usr/bin/ifconfig locknic0 inet delete > /dev/null 2>&1
	/usr/bin/ifconfig ue0 inet delete > /dev/null 2>&1
	/usr/bin/ifconfig em0 inet delete > /dev/null 2>&1
	/usr/bin/ifconfig re0 inet delete > /dev/null 2>&1
}

sshd_stop() {
	echo "[ssh] [srv] [interface] stop action triggered!" | logger
	sshd_reset
	sh /etc/action/beep ERR
}

sshd_start_ue0() {
	export ssh_local_ip="invalid"
	echo "[ssh] [srv] [airgap] start action devd triggered!" | logger
	case "$(ifconfig $ssh_local_if | grep ether | sha256)" in
	$ssh_mac1)
		for SERIAL in $(usbconfig dump_all_desc | grep iSerialNumber); do
			if [ "$(echo $SERIAL | sha256)" = "$ssh_ser1" ]; then
				adapter="one"
				export ssh_local_ip="10.10.250.10"
				break
			fi
		done
		;;
	$ssh_mac2_)
		for SERIAL in $(usbconfig dump_all_desc | grep iSerialNumber); do
			if [ "$(echo $SERIAL | sha256)" = "$ssh_ser2" ]; then
				adapter="two"
				export ssh_local_ip="10.10.250.11"
				break
			fi
		done
		;;
	esac
	if [ "$ssh_ip" != "invalid" ]; then
		echo "[ssh] [srv] [devd] [airgap] adapter $adapter authenticated" | logger
		sshd_reset
		/usr/bin/ifconfig $ssh_local_if name $ssh_local_if_target
		export ssh_local_if=$ssh_local_if_target
		/usr/bin/ifconfig $ssh_local_if inet $ssh_local_ip netmask $ssh_local_nm
		/usr/bin/ifconfig $ssh_local_if description "$ssh_local_if ssh link via authenticated adapter [$adapter]"
		if [ -x /usr/bin/wg ]; then sshd_start_wg0; fi
		sh /etc/action/beep
		for SERVER in $SSH_SERVER; do
			sh /etc/ssh/$SERVER/.init.sh start
		done
	else
		echo "[ssh] [$interface] change detected -> adapter not authenticated for ssh startup" | logger
		exit 1
	fi
}

sshd_start_internal_interface() {
	export ssh_local_if="$adapter"
	export ssh_local_ip="10.10.250.10"
	echo "[ssh] [airgap] start action devd triggered!" | logger
	sshd_reset
	/usr/bin/ifconfig $ssh_local_if inet $ssh_local_ip netmask $ssh_local_nm
	/usr/bin/ifconfig $ssh_local_if description "ssh link via authenticated adapter [$adapter]"
	if [ -x /usr/bin/wg ]; then sshd_start_wg0; fi
	sh /etc/action/beep
	for SERVER in $SSH_SERVER; do
		sh /etc/ssh/$SERVER/.init.sh start
	done
}

sshd_start_wg0() {
	echo "[ssh] [srv] [devd] [wg] startup interface wg0 via authenticated adapter $adaper / $ssh_local_if / $ssh_local_ip" | logger
	/usr/bin/ifconfig wg0 down > /dev/null 2>&1
	/usr/bin/ifconfig wg0 inet delete > /dev/null 2>&1
	/usr/bin/ifconfig wg0 destroy > /dev/null 2>&1
	/usr/bin/ifconfig wg0 create
	/usr/bin/ifconfig wg0 description "wireguard tunnel via authenticated adapter $adaper / $ssh_local_if / $ssh_local_ip"
	/usr/bin/wg setconf wg0 /etc/wg/sshd.ini
	/usr/bin/ifconfig wg0 inet 192.168.250.10 netmask 255.255.255.0 broadcast 192.168.250.255
	/usr/bin/ifconfig wg0 up
	/usr/bin/ifconfig wg0 debug
}

# external interface
case $1 in
startue0)
	sshd_start_ue0
	;;
startem0)
	export adapter="em0"
	sshd_start_internal_interface
	;;
startre0)
	export adapter="re0"
	sshd_start_internal_interface
	;;
stop)
	sshd_stop
	;;
esac
