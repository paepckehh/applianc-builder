#!/bin/sh
if [ $1 ]; then
	sh /etc/goo/markdownfmt -d -w $*
else
	sh /etc/goo/markdownfmt -d -w *.md
fi
