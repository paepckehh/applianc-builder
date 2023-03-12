#/bin/sh
git_create() {
	if [ ! $GIT_DEFAULT_BRANCH ]; then GIT_DEFAULT_BRANCH=main; fi
	git init --initial-branch=$GIT_DEFAULT_BRANCH --shared=world
	git_compliance_conf
	git pack-refs --all
	git gc --aggressive
}
git_compliance_conf() {
	$CMD log.date iso-local
	$CMD core.bare true
	$CMD core.filemode true
	$CMD core.trustctime false
	$CMD core.compression 9
	$CMD core.loosecompression 9
	$CMD core.commitGraph false
	$CMD core.logallrefupdates false
	$CMD core.untrackedCache true
	$CMD core.fsync none
	$CMD gc.writeCommitGraph false
	$CMD gc.packRefs true
	$CMD gc.reflogExpire now
	$CMD gc.auto 128
	$CMD gc.aggressiveDepth 64
	$CMD gc.aggressiveWindow 300
	$CMD index.threads 0
	$CMD index.version 4
	$CMD pack.threads 0
	$CMD pack.compression 9
	$CMD pack.depth 64
	$CMD pack.window 300
	$CMD pack.deltaCacheSize 0
	$CMD pack.deltaCacheLimit 65535
	$CMD pack.allowPackReuse false
	$CMD pack.useBitmaps false
	$CMD pack.useSparse false
	$CMD pack.writeBitmapHashCache false
	$CMD pack.windowMemory 0
	$CMD repack.useDeltaBaseOffset true
	$CMD repack.writeBitmaps false
	$CMD repack.updateServerInfo false
	$CMD feature.manyfiles true
	$CMD fetch.parallel 16
	$CMD fetch.fsckObjects true
	$CMD transfer.fsckObjects true
	$CMD http.sslVerify true
	$CMD http.sslVersion tls1.3
	$CMD http.followRedirects false
	$CMD http.maxRequests 8
	$CMD http.delegation none
	$CMD http.userAgent git
	$CMD receive.fsckObjects true
	$CMD receive.updateServerInfo false
	$CMD pull.ff only
	$CMD merge.ff only
	$CMD remote.origin.mirror true
}
git_compliance_check() {
	DTFS=$(date "+%Y%m%d%H%M")
	case $(diff -q .git/config $REPO/.git.conf/$LINE.config 2>&1) in
	Files*)
		echo "### !ALERT! ### $LINE/.git/config change detected, timestamp: $DTFS, details recorded!"
		mkdir -p $REPO/.git.conf/.log
		diff -u $REPO/.git.conf/$LINE.config .git/config
		diff -u $REPO/.git.conf/$LINE.config .git/config >> $REPO/.git.conf/.log/$LINE.config.log
		rm -rf $REPO/.git.conf/$LINE.config > /dev/null 2>&1
		rm -rf $REPO/.git.conf/.log/$LINE.config.2* 2>&1
		cp .git/config $REPO/.git.conf/.log/$LINE.config.$DTFS
		ln -fs $REPO/.git.conf/.log/$LINE.config.$DTFS $REPO/.git.conf/$LINE.config
		;;
	diff*)
		mkdir -p $REPO/.git.conf/.log
		rm -rf $REPO/.git.conf/$LINE.config 2>&1
		rm -rf $REPO/.git.conf/.log/$LINE.config.2* 2>&1
		cp .git/config $REPO/.git.conf/.log/$LINE.config.$DTFS
		ln -fs $REPO/.git.conf/.log/$LINE.config.$DTFS $REPO/.git.conf/$LINE.config
		;;
	esac
}
REPO=$BSD_GIT/.repo
LINE="$(pwd -L | cut -f 6 -d '/')"
CMD="git config --local"
if [ -e .git/config ]; then
	git_compliance_conf
	# git_compliance_check
else
	echo "... create git repo $LINE"
	git_create
fi
#########################
# $CMD merge.verifySignatures
# $CMD http.pinnedpugkey sha256//
# $CMD --add remote.origin.fetch "+refs/notes/*:refs/notes/*"
# $CMD core.logallrefupdates true
# $CMD merge.branchdesc true
# $CMD merge.log true
