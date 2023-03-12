#!/bin/sh
. /etc/action/.check.store
STORE=$BSD_GIT/.repo
# export GIT_CURL_VERBOSE=true
# export CURLOPT_PINNEDPUBKEY=sha256//$TARGET_KEYPIN
# export CURLOPT_VERBOSE=true
export ALLOWED_CIPHERS_TLS13=TLS_CHACHA20_POLY1305_SHA256
export ALLOWED_KEX_CURVES=X25519
export HTTPS_PROXY="http://127.0.0.80:8080"
export HTTP_PROXY="http://127.0.0.80:8080"
export CERT_FILE=/etc/ssl/rootCA.pem
export GIT_SSL_VERSION=tlsv1.3
export GIT_SSL_CAINFO=$CERT_FILE
export GIT_HTTP_MAX_REQUESTS=4
export CURLOPT_SSL_CURVES_LIST=$ALLOWED_KEX_CURVES
export CURLOPT_SSL_CAPATH=$CERT_FILE
export CURLOPT_SSL_CAINFO=$CERT_FILE
export CURLOPT_SSL_PROXY_SSL_CAINFO=$CERT_FILE
export GIT_HTTP_USER_AGENT=git
if [ ! $1 ]; then
	echo "... please specify url and optional target directory"
	echo "Example [generic] git.clone https://git.freebsd.org/src.git freebsd"
	echo "Example [github magic] git.clone lz4/lz4 lz4"
	echo "Example [go magic] git.clone mvcan.cc/sh go"
	exit
fi
if [ "$(echo $1 | cut -c 1-5)" != "https" ]; then
	echo "... https url missing, assume github.com repo!"
	REPO="https://github.com/$1"
else
	REPO=$1
fi
if [ $2 ]; then
	if [ "$2" == "go" ]; then
		TDIR="go-$(echo $REPO | sed -e 's/https:\/\///g' | sed -e 's/\//_/g' | sed -e 's/\./_/g')"
	else
		TDIR=$2
	fi
else
	TDIR="$(echo $REPO | sed -e 's/https:\/\///g' | sed -e 's/\//_/g' | sed -e 's/\./_/g')"
fi

if [ -x $STORE/$TDIR ]; then echo "... repo already exitsts!" && exit; fi
echo "... git clone $REPO -> $TDIR"
mkdir -p $STORE/$TDIR/.git && cd $STORE/$TDIR
chown -R gitclient:gitclient $STORE/$TDIR
/usr/bin/su gitclient -c "sh /etc/action/.action-git-config.sh"
/usr/bin/su gitclient -c "/usr/bin/git remote remove origin"
/usr/bin/su gitclient -c "/usr/bin/git remote add origin $REPO"
/usr/bin/su gitclient -c "/usr/bin/git fetch --all --force --jobs 4 --multiple --ipv4"
/usr/bin/su gitclient -c "/usr/bin/git remote update"
/usr/bin/su gitclient -c "/usr/bin/git gc"
HEADS="main master head trunk auto Main Head Trunk Auto develop dev DEV"
for HEAD in $HEADS; do
	TARGETHEAD=$(cat .git/packed-refs | grep $HEAD)
	if [ "$TARGETHEAD" != "" ]; then
		echo "ref: refs/remotes/origin/$HEAD" > .git/HEAD
		echo "found new bare mirror head -> ref: refs/remotes/origin/$HEAD"
		break
	fi
done
rm -rf .git/description .git/hooks > /dev/null 2>&1
/usr/bin/su gitclient -c "sh /etc/action/.action-git-config.sh"
echo $TDIR >> $STORE/active
cd $BSD_GIT && ln -fs .repo/$TDIR $TDIR
sync && sync && sync
####################################################################################
