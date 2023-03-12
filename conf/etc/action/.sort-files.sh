#!/bin/sh
find . -type f | while read LINE; do
	case $LINE in
	"") ;;
	*action*) ;;
	*)
		echo "... process $LINE"
		if [ -x /usr/bin/sponge ]; then
			cat $LINE | sort -u | sponge $LINE
		else
			echo "    -> please install sponge tool, activate whack hacky workaround"
			cat $LINE | sort -u > x && mv x $LINE
		fi
		;;
	esac
done
