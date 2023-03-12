#!/bin/sh
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
if [ ! -x $BSD_GIT ]; then echo "... git store not mounted!" && exit; fi
if [ "$(/usr/bin/id -un)" != "gitclient" ]; then su gitclient -c "sh /etc/action/.action-git-github-keys.sh" && exit; fi
PARALLEL=25
DTS=$(date "+%Y%m%d")
TEMPDIR="/var/tmp/.gitkeylist.d.$DTS"
KEYSDIR="$BSD_GIT/.keys.github"
STATDIR="$BSD_GIT/.stat.github"
mkdir -p $TEMPDIR $KEYSDIR/.store $KEYSDIR/.changelog $STATDIR
github_keys() {
	TEMPFILE=$TEMPDIR/$TARGET
	KEYSFILE=$KEYSDIR/$TARGET
	KEYSDIFF=$KEYSDIR/.changelog/$TARGET.diff
	KEYFINAL=$KEYSDIR/.store/$TARGET.$DTS
	touch $KEYSFILE $TEMPFILE $KEYSFINAL $KEYSDIFF
	$CURL_CMD_PROXY -s https://github.com/$TARGET.keys > $TEMPFILE
	DIFF=$(diff -u $KEYSFILE $TEMPFILE)
	if [ "$DIFF" != "" ]; then
		echo $DIFF
		echo $DIFF >> $KEYSDIFF
		cp -f $TEMPFILE $KEYFINAL
		rm -f $KEYSFILE
		ln -fs $KEYFINAL $KEYSFILE
		CURRENT=$(cat "$KEYFINAL")
		rm -rf $KEYSDIR/.store/$TARGET.* > /dev/null 2>&1
		echo $CURRENT > $KEYFINAL
	fi
	echo "## [done] [keyset] $TARGET"
}
github_state() {
	STATE=$STATDIR/$TARGET.$REPO
	STATE_FILE=$STATE.$DTS
	rm -rf $STATE.*
	touch $STATE_FILE
	$CURL_CMD_PROXY -s https://api.github.com/repos/$TARGET/$REPO > $STATE_FILE
	REPODATE=$(cat $STATE_FILE | grep pushed_at | cut -c 17-36)
	ISSUES=$(cat $STATE_FILE | grep open_issues_count | cut -c 23-)
	if [ -x $BSD_GIT/$REPO ]; then
		rm -rf $GIT/$REPO/.state.api-github.*
		cp -rf $STATE_FILE $GIT/$REPO/.state.api-github.$DTS
	fi
	echo "## [done] [states] $TARGET.$REPO, Issues: $ISSUES Last Commit: $REPODATE"
}
cd $ST
LIST=$(ls -I $GIT/.git.conf | sort --random-sort)
for CONF in $LIST; do
	ITEM="$(cat $GIT/.git.conf/$CONF | grep 'url = https://github.com/' | grep -v '#')"
	case $ITEM in
	"")
		continue
		;;
	*)
		export TARGET=$(echo $ITEM | cut -c 26- | cut -d '/' -f 1)
		export REPO=$(echo $ITEM | cut -c 26- | cut -d '/' -f 2 | sed -e 's/.git$//g')
		github_keys &
		# github_state &
		jobs -lp > /var/tmp/.$PPID
		while [ $(cat /var/tmp/.$PPID | wc -l) -gt $PARALLEL ]; do
			sleep 0.1 && jobs -lp > /var/tmp/.$PPID
		done
		;;
	esac
done
wait
rm -rf $TD
sync && sync && sync
exit
###########################################################################
