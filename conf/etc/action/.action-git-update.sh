#!/bin/sh
REPO=$BSD_GIT/.repo
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
if [ "$(/usr/bin/id -un)" != "gitclient" ]; then su gitclient -c "sh /etc/action/.action-git-update.sh $1" && exit; fi
if [ ! -x /usr/store/git ]; then echo "... git store not mounted!" && exit; fi
LOCKFILE=/var/tmp/lock.git.update
if [ -e $LOCKFILE ]; then echo "... update already active! [ $LOCKFILE lockfile exists ]" && exit; fi
touch $LOCKFILE
PARALLEL=8
echo "parallel sessions: $PARALLEL"
DTS=$(date "+%Y%m%d-%H%M%S")
LOG="/var/tmp/git.update.$DTS"
touch $LOG
GITCMD="/usr/bin/git"
config_http() {
	# export CURLOPT_PINNEDPUBKEY=sha256//$TARGET_KEYPIN
	# export CURLOPT_RESOLVE=$IP
	# export CURLOPT_SSLCERT CURLOPT_KEYPASSWD CURLOPT_CERT
	# export GIT_CURL_VERBOSE=true
	# export CURLOPT_VERBOSE=true
	# export GVERBOSE=true
	# export CURLOPT_SSL_CERT=$CLIENT_CERT_FILE
	# export CURLOPT_SSL_KEYPASSWD=$CLIENT_CERT_PWD
	unset GIT_SSL_CAPATH
	unset GITVERBOSE
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
	# hq v $GIT_SSL_CAINFO.hqs
}
action() {
	cd $REPO/$LINE
	if [ $GVERBOSE ]; then
		export GITVERBOSE=true
		export GIT_CURL_VERBOSE=1
		$GITCMD fetch -v $FETCHOPTS
	else
		# $GITCMD remote update --prune >> $LOG
		echo "## [start] doasgit fetch --> $LINE" >> $LOG
		$GITCMD fetch $FETCHOPTS
		echo "## [done] doasgit fetch --> $LINE"
	fi
	sync
}
bg_cache_conf() {
	find $REPO/ | grep 'config$' | xargs cat > /dev/null 2>&1
}
SLEEPLOOP=0
# bg_cache_conf &
config_http
cd $REPO
case $(cat .repo.key) in
216535fe4be40f6eeb7d6824e1e3cda7020aa912a908d3eb550bf52e)
	FETCHOPTS="--all --force --tags --prune --prune-tags --show-forced-updates --ipv4 --no-auto-gc --no-write-fetch-head"
	if [ $1 ] && [ -x $REPO/$1 ]; then
		cd $REPO/$1
		echo "#### INDIVIDUAL REPO UPDATE ----> $1"
		echo "doasgit fetch -v $FETCHOPTS"
		LOOP=false
		export GVERBOSE=true
		LINE=$1
		action
	else
		ALL_TARGET=$BSD_GIT && if [ "$1" == "all" ]; then ALL_TARGET=$REPO; fi
		echo "... updating all repos [$ALL_TARGET]"
		echo "doasgit fetch $FETCHOPTS"
		echo "########################################################################################"
		LOOPLIST=$(ls -I $ALL_TARGET | sort --random-sort)
		for LINE in $LOOPLIST; do
			if [ -x $REPO/$LINE ]; then
				action &
				jobs -lp > /var/tmp/.$PPID
				while [ $(cat /var/tmp/.$PPID | wc -l) -gt $PARALLEL ]; do
					sleep 0.1 && jobs > /var/tmp/.$PPID
				done
			fi
		done
		wait
		rm /var/tmp/.$PPID
	fi
	;;
esac
wait
echo "... done!"
sync && sync && rm -f $LOCKFILE
