#!/bin/sh
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
if [ ! -x $BSD_GIT ]; then echo "... git store not mounted!" && exit; fi
if [ ! -x /.worker/goproxy/mnt/gomod/pkg ]; then /usr/sbin/service xxgoproxy onestart; fi
# lockdown the sumdb public key!
export GOSUMDB_PUBKEY="033de0ae+Ac4zctda0e5eza+HJyk9SxEdh+s3Ux18htTTAD8OuAn8"
export GOSUMDB="sum.golang.org+$GOSUMDB_PUBKEY"
export SSL_CERT_FILE="/etc/ssl/rootCA.pem"
export SSL_CERT_DIR="/etc/ssl"
export GOPROXY_SERVER="https://goproxy.local:443"
export GOPROXY_LOCAL="paepcke.de"
export GOPROXY="$GOPROXY_SERVER"
export GOPRIVATE=$GOPROXY_LOCAL
export GOPATH="/usr/local/go"
unset HTTPS_PROXY HTTP_PROXY
if [ ! -x /usr/local/go/bin/go ]; then sh $BSD_BIN/BSDlive go; fi
echo "ENV GOPROXY $GOPROXY"
DAY=$(date "+%Y%m%d")
# input validation
if [ ! $1 ]; then
	echo "... please specify git repo / and app name / optional: clean !"
	echo "EXAMPLE: sh ./action-git-re-vendor.sh go-miniflux clean"
	exit

fi
action() {
	GITLINK=$BSD_GIT/$APP
	if [ -e $GITLINK/.git/config ]; then
		REPOURL=$(cat $GITLINK/.git/config | grep https)
	elif [ -e /tmp/GIT/$APP/.git/config ]; then
		REPOURL=$(cat /tmp/GIT/$APP/.git/config | grep https)
	else
		echo "unable to find git repo!"
	fi
	GOREPO=$(echo $REPOURL | cut -c 15-)
	echo "Starting clean re-vendor!"
	echo "GIT REPO: $GITLINK"
	echo "GIT URL: $REPOURL"
	echo "GO REPO: $GOREPO"
	rm -rf /usr/store/eXchange/$APP > /dev/null 2>&1
	mkdir -p /usr/store/eXchange/$APP
	cd /usr/store/eXchange
	sh /etc/action/store gitcheckout $APP patchkeep
	cd $APP
	if [ -x vendor ]; then
		mv vendor vendor.orig.$DAY
		mkdir -p vendor
	fi
	TARGET_DIR=$BSD_GOMOD/.vendor
	go mod tidy -e -v -go=1.18
	go mod verify
	go mod vendor -v
	if [ "$GOSUMDB" != "sum.golang.org+033de0ae+Ac4zctda0e5eza+HJyk9SxEdh+s3Ux18htTTAD8OuAn8" ]; then
		echo "ALERT: GOSUMDB PUBLIC KEY ENV MODIFIED!"
		echo "EXPECTED: sum.golang.org+033de0ae+Ac4zctda0e5eza+HJyk9SxEdh+s3Ux18htTTAD8OuAn8"
		echo "FOUND:    $GOSUMDB"
		exit
	fi
	cd vendor
	rm -rf modules.txt
	mkdir -p golang.org
	cd golang.org
	rm -rf x
	ln -fs /usr/local/xvendor x
	cd /usr/store/eXchange/$APP
	mkdir -p $TARGET_DIR/.attic
	mv $TARGET_DIR/$APP-2* $TARGET_DIR/.attic/
	tar -cf - go.sum go.mod vendor | zstd -vv -c -T0 > $TARGET_DIR/$APP-$DAY.tar.zst
	echo "... [done] golang re-vendor: $APP !"
}
export OPT=$2

case $1 in
all) ACTION_LIST=$(cat $BSD_GIT/.golang-re-vendor) ;;
*) ACTION_LIST=$1 ;;
esac

for APP in $ACTION_LIST; do
	(action)
done
exit
######################################################
