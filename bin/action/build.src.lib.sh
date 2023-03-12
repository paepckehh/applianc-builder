#!/bin/sh
####################################
### CONFIGURATION SETUP SECTION  ###
####################################
build_src_conf() {
	if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
	if [ ! $SRC_CHECKOUT ]; then export SRC_CHECKOUT=HEAD; fi
}
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
build_src_check_srcimg() {
	if [ ! -h $BSD_PKG/all/fbsd.$SRC_CHECKOUT ]; then
		echo "... $SRC_CHECKOUT.img.ulzma is missing!"
		echo "... recreate the missing src checkout image"
		sh /etc/action/store src.rebuild
	fi
}
build_src_check_src() {
	if [ ! -x /usr/src/$SRC_CHECKOUT/usr.bin ]; then
		mkdir -p /usr/src/$SRC_CHECKOUT > /dev/null 2>&1
		if [ ! -x /usr/src/$SRC_CHECKOUT ]; then
			mount -t tmpfs tmpfs /usr/src
			mkdir -p /usr/src/$SRC_CHECKOUT > /dev/null 2>&1
		fi
		mdconfig -d -u $BSD_MD_SRC > /dev/null 2>&1
		mdconfig -u $BSD_MD_SRC -o async -f $BSD_PKG/all/fbsd.$SRC_CHECKOUT
		mount -r /dev/$BSD_MD_SRC.uzip /usr/src/$SRC_CHECKOUT
	fi
}
build_src_check_verify() {
	if [ ! -x /usr/src/$SRC_CHECKOUT/usr.bin ]; then
		echo "### ERROR: existing srcimg seem to be defect, hard delete and rebuild $SRC_CHECKOUT img now! #################"
		rm -rf $BSD_PKG/all/fbsd.$SRC_CHECKOUT*
		rm -rf $BSD_PKG/all/.store/fbsd.$SRC_CHECKOUT*
		src_check_srcimg
		src_check_src
	fi
}
build_src_main() {
	build_src_conf
	build_src_check_srcimg
	build_src_check_src
	build_src_check_verify
	echo "... src tree checkout/verify successfully done for $SRC_CHECKOUT!"
}
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
build_src() {
	build_src_main
}
####################################
###  EXTERNAL COMMAND INTERFACE  ###
####################################
if [ $2 ]; then export SRC_CHECKOUT=$2; fi
case $1 in
build*) build_src_main ;;
esac
###################################
