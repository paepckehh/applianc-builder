#!/bin/sh
if [ ! -x /usr/store/git ]; then echo "unable to access store" && exit 1; fi
if [ -z "$GITACTION" ]; then echo "no git action set" && exit 1; fi
export REPONAME="${PWD##*/}"
export NIC_LOCAL_IP="$(cat /var/uplink.0.ip4)"
export NIC_LOCAL_IF="$(cat /var/uplink.0.interface)"
export GIT_SSH_COMMAND="ssh -4akxy \
			-i $BSD_KEY/id/id_ed25519 \
			-m hmac-sha2-512-etm@openssh.com \
			-c chacha20-poly1305@openssh.com \
			-o MACs=hmac-sha2-512-etm@openssh.com \
			-o Ciphers=chacha20-poly1305@openssh.com \
			-o KexAlgorithms=curve25519-sha256 \
			-o PubkeyAcceptedKeyTypes=ssh-ed25519 \
			-o UserKnownHostsFile=$BSD_KEY/id/known_hosts \
			-o StrictHostKeyChecking=yes \
			-o UpdateHostKeys=no \
			-o ServerAliveInterval=120 \
			-o ServerAliveCountMax=3 \
			-o TCPKeepAlive=no \
			-o Tunnel=no \
			-o VisualHostKey=no \
			-o Compression=no \
			-o VerifyHostKeyDNS=no \
			-o AddKeysToAgent=no \
			-o ForwardAgent=no \
			-o ClearAllForwardings=yes \
			-o IdentitiesOnly=yes \
			-o IdentityAgent=none \
			-b $NIC_LOCAL_IP \
			-B $NIC_LOCAL_IF"
export ALLOWED_CIPHERS_TLS13=TLS_CHACHA20_POLY1305_SHA256
export ALLOWED_KEX_CURVES=X25519
export CERT_FILE=/etc/ssl/external_trust.pem
export SSL_CERT_FILE=$CERT_FILE
export GIT_SSL_CAINFO=$CERT_FILE
export GIT_SSL_VERSION=tlsv1.3
export CURLOPT_SSL_CURVES_LIST=$ALLOWED_KEX_CURVES
export CURLOPT_SSL_CAPATH=$CERT_FILE
export CURLOPT_SSL_CAINFO=$CERT_FILE
export CURLOPT_SSL_PROXY_SSL_CAINFO=$CERT_FILE
export CURLOPT_SSL_CAPATH="/etc/ssl/externa;_trust.pem"
export GIT_HTTP_USER_AGENT=git
export GCMD="/usr/bin/setfib 6 /usr/bin/git"
export GITCMD="$GCMD $GITACTION"
export REPOS="codeberg.org github.com gitlab.com sr.ht"
unset HTTPS_PROXY HTTP_PROXY
for DOM in $REPOS; do
	if [ -e ".$DOM" ]; then
		PROTO="ssh://" && USR="paepcke" && ID="git" && TARGETID="/$USR" && SUFFIX="" && ADDR="$DOM"
		case $DOM in
		github.com) ADDR="140.82.114.3" TARGETID="/paepckehh" ;;
		codeberg.org) ADDR="217.197.91.145" ;;
		gitlab.com) ADDR="172.65.251.78" ;;
		sr.ht) ADDR="173.195.146.142" TARGETID="/~paepcke" ;;
		esac
		case $PROTO in
		https://) ID="$USR:$(cat $BSD_KEY/$DOM/api)" && TARGETID="/$USR" && ADDR="$DOMPREFIX$DOM" ;;
		esac
		URL="$PROTO$ID@$ADDR$TARGETID/$REPONAME$SUFFIX"
		echo "########################################################################"
		echo "### UPDATE: $PROTO $ID @ $DOM $TARGETID /$REPONAME [$URL]"
		XCMD="$GITCMD $URL" && $XCMD
	fi
done
