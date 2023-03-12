#!/bin/sh
if [ $1 ]; then
	sh /etc/goo/goo.shfmt -d -ln posix -bn -sr -s -w $*
else
	sh /etc/goo/goo.shfmt -d -ln posix -bn -sr -s -w *.sh
fi
