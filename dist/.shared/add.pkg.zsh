#!/bin/sh
export BSD_DIST_PKG="$BSD_DIST_PKG zsh"
export BSD_ADD_ETC_PASSWD="$BSD_ADD_ETC_PASSWD
zsh::0:0::0:0:alternative shell root user:/root:/usr/bin/zsh"
. $BSD_DIST/.shared/add.pkg.calendar
