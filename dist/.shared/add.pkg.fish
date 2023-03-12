#!/bin/sh
export BSD_DIST_PKG="$BSD_DIST_PKG fish pcre2"
export BSD_ADD_ETC_PASSWD="$BSD_ADD_ETC_PASSWD
fish::0:0::0:0:alternative shell root user:/root:/etc/action/privatefish"
. $BSD_DIST/.shared/add.pkg.calendar
