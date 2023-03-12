#!/bin/sh
# . /etc/ssh/airgap-server-ed25519/.init.keys
. /etc/ssh/airgap-server-ed25519/.init.conf

sshd_reset() {
	echo "[sshd] [airgap] reset action triggered!" | logger
	/bin/pkill sshd
	if [ -e /var/lock.init.airgap-server-ed25519 ]; then rm /var/lock.init.airgap-server-ed25519; fi
}

sshd_stop() {
	echo "[sshd] [airgap] stop action triggered!" | logger
	sshd_reset
	/sbin/pfctl -e
	/sbin/pfctl -F all
	/sbin/pfctl -f /etc/pf.conf || /sbin/pfctl -f /etc/pf.conf.blockall
	sh /etc/action/beep
}

sshd_start() {
	echo "[devd] [sshd] [airgap] start action triggered!" | logger
	if [ "$ssh_local_ip" != "invalid" ]; then
		echo "[devd] [sshd] [airgap] [$adapter] successful authenticated" | logger
		sshd_reset
		/sbin/pfctl -e
		/sbin/pfctl -F all
		/sbin/pfctl -f /etc/pf.conf.ssh-server-ed25519 || /sbin/pfctl -f /etc/pf.conf.blockall
		if [ -x /usr/bin/ssproxys ]; then
			/usr/bin/daemon -S -R 10 /usr/bin/ssproxys
			$ssh_command $ssh_command_args_localhost || sh /etc/action/beep alert
		fi
		$ssh_command $ssh_command_args_external || sh /etc/action/beep alert
		sh /etc/action/beep
		touch /var/lock.init.airgap-server-ed25519
	else
		echo "[sshd] [airgap] [$interface] change detected -> adapter not authenticated for sshd startup" | logger
		exit 1
	fi
}

# external interface
case $1 in
start) sshd_start ;;
stop) sshd_stop ;;
esac
