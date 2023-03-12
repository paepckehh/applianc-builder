#!/bin/sh
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
if [ ! -x $BSD_GIT ]; then echo "... git store not mounted!" && exit; fi
TARGETDIR=$BSD_GIT/.keys
T2=/tmp/.connect.kex.log.temp
F2=$TARGETDIR/.connect.kex.log
CHANGELOG=$TARGETDIR/.changelog
DTSF=$(date "+%Y%m%d%H%M%S")
TEMPKEYDIR=/tmp/keyscan
ARC=$(uname -m)
case $ARC in
amd64)
	PARALLEL=8
	OUTBOUND_LIMIT=0.3
	;;
*)
	PARALLEL=2
	OUTBOUND_LIMIT=2
	;;
esac
echo "$ARC plattform specific parallel sessions: $PARALLEL"
echo "outbound limit: new sessions every $OUTBOUND_LIMIT secconds"
echo "store: $BSD_GIT"
PARALLEL=$((PARALLEL - 1))

rm -rf $TEMPKEYDIR > /dev/null 2>&1
mkdir -p $TEMPKEYDIR
mkdir -p $TARGETDIR
mkdir -p $CHANGELOG
rm -rf $T2
rm -rf $F2

SSH_CMD=/usr/bin/ssh
KEYSCAN_CMD=/usr/bin/ssh-keyscan
PFCTL_CMD=/usr/bin/pfctl
echo "### OPENSSH VERSION ###"
$SSH_CMD -V
LOCKFILE=/var/lock.git.ssh.keys
while [ -e $LOCKFILE ]; do
	sleep 3
	echo "$LOCKFILE exists!"
	sync && sync && sync
done
echo $PPID > $LOCKFILE
prep_log() {
	echo "" >> $T2
	echo "" >> $T2
	echo "@@@" >> $T2
	echo "##############################################################################################################" >> $T2
	echo "##############################################################################################################" >> $T2
	echo "##############################################################################################################" >> $T2
	echo "### $DTSF" >> $T2
	echo -n "### " >> $T2
	$SSH_CMD -V >> $T2 2>> $T2
	echo "##############################################################################################################" >> $T2
	echo ""
}

bg_cache() {
	find $TARGETDIR/known_hosts.* | xargs cat > /dev/null 2>&1
	cat $F2 > /dev/null 2>&1
}

open_fw() {
	echo ""
	uplinkip4="$(cat /var/uplink.0.ip4)"
	if [ -n "$uplinkip4" ]; then
		echo "... open firewall ssh outbound! [$uplinkip4]"
		$PFCTL_CMD -t sshout -T add "$uplinkip4"
		$PFCTL_CMD -t sshout -vvT show
		# UPSTREAM BUGREPORT FBSD PF - broken stats report
	else
		echo "... unable to find uplink information for firwall change!"
	fi
}

close_fw() {
	echo "... close/destroy firewall ssh outbound now!"
	$PFCTL_CMD -t sshout -T flush
	$PFCTL_CMD -t sshout -vvT show
}

finish_log() {
	echo "... consolidate and repack connection/debug logs!"
	rm -rf $F2
	unzstd -q $F2.zst
	cat $T2 >> $F2
	rm $F2.zst
	zstd -19 --long --ultra $F2
	rm -rf $F2
	rm -rf $T2
}

action() {
	TARGET_HOST=$(echo $LINE | cut -c 13-)
	T1=$TEMPKEYDIR/$LINE
	T3=$T2.$TARGET_HOST
	touch $T1 $T3
	chown ssh:ssh $T1 $T3
	echo "##############################################" >> $T3
	echo "### TIMESTAMP $TARGET_HOST $(date "+%Y%m%d%H%M%S") " >> $T3
	echo "### TIMESTAMP ### CERT $TARGET_HOST $(date "+%Y%m%d%H%M%S") " >> $T3
	su ssh -c "setfib 6 $KEYSCAN_CMD -v -4 -p 22 -T 120 -c $TARGET_HOST >> $T1 2>> $T3"
	echo "## [done] CERT    SSH KEYSCAN  for target:	-->	$TARGET_HOST"
	echo "### TIMESTAMP ### ED22519 $TARGET_HOST $(date "+%Y%m%d%H%M%S") " >> $T3
	su ssh -c "setfib 6 $KEYSCAN_CMD -v -4 -p 22 -T 120 -t ed25519 $TARGET_HOST >> $T1 2>> $T3"
	echo "## [done] ED25519 SSH KEYSCAN  for target:	-->	$TARGET_HOST"
	echo "### TIMESTAMP ### ECDSA $TARGET_HOST $(date "+%Y%m%d%H%M%S") " >> $T3
	su ssh -c "setfib 6 $KEYSCAN_CMD -v -4 -p 22 -T 120 -t ecdsa $TARGET_HOST >> $T1 2>> $T3"
	echo "## [done] ECDSA   SSH KEYSCAN  for target:	-->	$TARGET_HOST"
	echo "### TIMESTAMP ### RSA $TARGET_HOST $(date "+%Y%m%d%H%M%S") " >> $T3
	su ssh -c "setfib 6 $KEYSCAN_CMD -v -4 -p 22 -T 120 -t rsa $TARGET_HOST >> $T1 2>> $T3"
	echo "## [done] RSA     SSH KEYSCAN  for target:	-->	$TARGET_HOST"
	echo "### DNSQUERY SSHFP ### drill +dnssec $TARGET_HOST SSHFP $(date "+%Y%m%d%H%M%S") " >> $T3
	drill +dnssec $TARGET_HOST SSHFP >> $T3 2>> $T3
	echo "## [done] SSHFP   DNS KEYDRILL for target:	-->	$TARGET_HOST"
	cat $T3 >> $T2
	rm -rf $T3
}

OPT=$1
if [ ! $1 ]; then OPT=all; fi

case $OPT in
all | archive | full)
	prep_log
	open_fw
	LIST=$(ls -I $TARGETDIR | sort --random-sort)
	for LINE in $LIST; do
		action
		# XXX broken builtins / pipe stdout / bug / workaround
		# fail: wait ; X=$( jobs | wc -l ) ; X=$( $(jobs) | wc -l )
		#jobs > /var/.$PPID
		#while [ $(cat /var/.$PPID | wc -l) -gt $PARALLEL ]; do
		#	sleep 0.3 && jobs > /var/.$PPID
		#done
		#jobs > /var/.$PPID
	done
	#wait
	#
	# while [ $(ps -aux | grep "keyscan" | wc -l) -gt 1 ]; do
	#	sleep 0.2
	# done
	close_fw
	echo ""
	echo "################## START RAW CONNECT LOG ###########################"
	cat $T2
	echo "##################  END  RAW CONNECT LOG ###########################"
	finish_log &
	echo "################## START KEY CHANGE LOG ############################"
	LIST=$(ls -I $TARGETDIR | sort)
	for LINE in $LIST; do
		TARGET_HOST=$(echo $LINE | cut -c 13-)
		T1=$TEMPKEYDIR/$TARGET_HOST
		CHANGE=$(diff -q $TARGETDIR/$LINE $TEMPKEYDIR/$LINE 2>&1)
		case $CHANGE in
		Files* | diff*)
			LOG=$CHANGELOG/$LINE.log.diff
			echo "### !ALERT! ### $LINE/.git/config change detected!"
			diff -u $TARGETDIR/$LINE $TEMPKEYDIR/$LINE
			echo $CHANGE_CONTENT
			echo "" >> $LOG
			echo "### DATE STAMP: $DTSF" >> $LOG
			echo $CHANGE_CONTENT >> $LOG
			diff -u $TARGETDIR/$LINE $TEMPKEYDIR/$LINE >> $LOG
			;;
		esac
	done
	echo "##################  END  KEY CHANGE LOG ############################"
	wait
	# XXX
	while [ $(ps -aux | grep "xz" | wc -l) -gt 1 ]; do
		echo -n "." && sleep 0.2
	done
	;;
*)
	open_fw
	mount -t tmpfs tmpfs /root/.ssh
	TARGET_HOST=$1
	echo "SSH KEYSCAN for target: 	$TARGET_HOST"
	echo "### TIMESTAMP $TARGET_HOST $(date "+%Y%m%d%H%M%S") "
	echo "### TIMESTAMP ### CERT $TARGET_HOST $(date "+%Y%m%d%H%M%S") "
	setfib 6 $KEYSCAN_CMD -v -4 -p 22 -T 120 -c $TARGET_HOST
	echo "### TIMESTAMP ### ED22519 $TARGET_HOST $(date "+%Y%m%d%H%M%S") "
	setfib 6 $KEYSCAN_CMD -v -4 -p 22 -T 120 -t ed25519 $TARGET_HOST
	echo "### TIMESTAMP ### ECDSA $TARGET_HOST $(date "+%Y%m%d%H%M%S") "
	setfib 6 $KEYSCAN_CMD -v -4 -p 22 -T 120 -t ecdsa $TARGET_HOST
	echo "### TIMESTAMP ### RSA $TARGET_HOST $(date "+%Y%m%d%H%M%S") "
	setfib 6 $KEYSCAN_CMD -v -4 -p 22 -T 120 -t rsa $TARGET_HOST
	setfib 6 $SSH_CMD -v -4 -p 22 $TARGET_HOST
	close_fw
	;;
esac
wait
rm -rf $TEMPKEYDIR > /dev/null 2>&1
rm -rf $LOCKFILE
exit
#################################################################
