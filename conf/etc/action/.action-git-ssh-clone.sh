#/bin/sh
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
if [ ! -x $BSD_GIT ]; then echo "... git store not mounted!" && exit; fi

if [ ! $1 ]; then
	echo "... please specify url and optional branch"
	echo "Example git-native https://github.com/lz4/lz4 dev"
	exit
fi

umount -f /.root/.ssh > /dev/null 2>&1
mount -t tmpfs tmpfs /root/.ssh
cat $GIT/.git.keys/known_hosts.* >> /root/.ssh/known_hosts
cd $BSD_GIT
ipfw delete 10104 > /dev/null 2>&1
if [ -e /var/pnoc/uplink-dhcp ]; then
	INTERFACE_ONE="$(grep "interface" /var/pnoc/uplink-dhcp | cut -c 13- | sed 's/;//' | sed 's/\"//g')"
	INTERFACE_ONE_IP="$(grep "fixed-address" /var/pnoc/uplink-dhcp | cut -c 17- | sed "s/;//")"
	GATEWAY_ONE="$(grep "option routers" /var/pnoc/uplink-dhcp | cut -c 18- | sed "s/;//")"
	NETMASK_ONE="$(grep "option subnet-mask" /var/pnoc/uplink-dhcp | cut -c 22- | sed "s/;//")"
else
	INTERFACE_ONE="ue1"
	INTERFACE_ONE_IP="192.168.8.2"
	GATEWAY_ONE="192.168.8.1"
	NETMASK_ONE="255.255.255.248"
fi
ipfw add 10104 allow tcp from $INTERFACE_ONE_IP to any 22 via $INTERFACE_ONE out setup keep-state :default
setfib 6 git clone -v --progress --no-checkout --jobs 4 --ipv4 --config fetch.parallel=8 -b $2 $1
sync && sync && sync
ipfw delete 10104
# umount -f /.root/.ssh > /dev/null 2>&1
exit
####################################################################################
