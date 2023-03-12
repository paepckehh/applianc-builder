#!/usr/bin/zsh
source /etc/action/.profile
source /etc/action/.interactive
source /etc/action/.bsdconf
source /etc/action/.alias.common

export SHELL=/usr/bin/zsh
export PS1="[%F{blue}zsh:root@%m%f] [%F{blue}%y%f] [%F{blue}%*%f] [%F{blue}%/%f] # "

setopt autocd
setopt list_packed
setopt rm_star_silent
setopt complete_in_word
setopt extendedglob
setopt bsd_echo
setopt posix_builtins

if [ $(/sbin/sysctl -n security.jail.jailed) -eq 0 ]; then
	sh /etc/rc.d/sysctl reload_verbose
	sysctl -a | grep temperature
	echo "system fingerprint: $(uname -m | sha224)#$(sysctl -b kern.build_id | sha224)"
	/sbin/kldstat -h
	/usr/bin/ncal -3w
	/bin/date
	if [ -e /root/.config/calendar/calendar.global ]; then
		echo "=== global events [+2d]"
		/usr/bin/calendar -W 2 -f /root/.config/calendar/calendar.global
	fi
	if [ -e /root/.config/calendar/calendar.sitelocal ]; then
		echo "=== site local events [+32d]"
		/usr/bin/calendar -W 32 -f /root/.config/calendar/calendar.sitelocal
	fi
	if [ -e /var/gps/.location ]; then
		. /var/gps/.location
		if [ $GPS_SUN_RISE ]; then
			echo "=== site  [airloctag $AIRLOCTAG] -> [lat $GPS_LAT] [long $GPS_LONG] [elevation $GPS_ELEVATION]"
			echo "=== today [sunrise  $GPS_SUN_RISE] [sunset $GPS_SUN_SET] [noon $GPS_SUN_NOON] [daylight $GPS_SUN_DAYLIGHT] $GPS_SUN_OPT"
		fi
	fi
fi
echo "=== distribution [$DIST] plattform [$SBC] [$SOC] [$ARCH_TRIPLE]"
