#!/bin/sh
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
. /etc/action/.check.store
. /etc/action/.check.sponge
. /etc/action/.check.golang
export REPO=$BSD_GIT/.repo
cd $BSD_GIT
case $(uname -m) in
amd64 | arm64) PARALLEL=$(($(/usr/bin/sysctl -n hw.ncpu) * 2)) ;;
*) PARALLEL=$(/usr/bin/sysctl -n hw.ncpu) ;;
esac
LOCKFILE=/var/tmp/lock.git.maintenance
TEMPGIT=/var/tmp/.git.repo.maintenance
while [ -e $LOCKFILE ]; do
	sleep 3
	echo "$LOCKFILE exists!"
	sync && sync && sync
done
echo $PPID > $LOCKFILE
git_action_sign() {
	COMMIT=$(su gitclient -c "git -C $REPO/$LINE show $CHECKOUT" | head -n 1)
	case $COMMIT in
	commit*) COMMIT=$(echo $COMMIT | cut -c 8-20) ;;
	tag*) COMMIT=$(echo $COMMIT | cut -c 5-) ;;
	esac
	TEMP=/var/tmp/.gitsnap
	STORE=$BSD_DEV/reposigs
	TARGET=$STORE/$LINE/$COMMIT
	mkdir -p $TEMP && mkdir -p $TARGET && cd $TEMP
	chown -R gitclient:gitclient $TEMP
	echo "### COMMIT $CHECKOUT expands to $COMMIT ###"
	/usr/bin/su gitclient -c "git -C $REPO/$LINE archive $CHECKOUT | tar -xf -"
	hq u && hq c
	mv .hqMAP* $TARGET
	rm -rf $TEMP
}
git_action_stats() {
	rm .stats.* > /dev/null 2>&1
	DTS=$(date +%Y%m%d)
	/bin/sh /etc/goo/goo.git-sizer > .stats.$DTS
	cat .stats.$DTS
}
git_action_aggressive() {
	echo "### aggressive ########################################################################"
	echo "---> $REPO/$LINE"
	cd $REPO/$LINE
	/usr/bin/su gitclient -c "sh /etc/action/.action-git-config.sh"
	/usr/bin/su gitclient -c '/usr/bin/git prune --expire=now'
	/usr/bin/su gitclient -c '/usr/bin/git reflog expire --expire-unreachable=now --rewrite --all'
	/usr/bin/su gitclient -c '/usr/bin/git pack-refs --all'
	/usr/bin/su gitclient -c '/usr/bin/git repack -n -a -d --depth=64 --window=300 --threads=0'
	/usr/bin/su gitclient -c '/usr/bin/git prune-packed'
	# git_action_stats
}
git_action_rebuild() {
	echo "### rebuild ########################################################################"
	echo "---> $REPO/$LINE"
	cd $REPO/$LINE
	/usr/bin/su gitclient -c "sh /etc/action/.action-git-config.sh"
	/usr/bin/su gitclient -c '/usr/bin/git prune --expire=now'
	/usr/bin/su gitclient -c '/usr/bin/git reflog expire --expire-unreachable=now --rewrite --all'
	/usr/bin/su gitclient -c '/usr/bin/git pack-refs --all'
	if [ -e .broken ]; then
		/usr/bin/su gitclient -c '/usr/bin/git repack -n -a -d --depth=64 --window=250 --threads=0'
	else
		/usr/bin/su gitclient -c '/usr/bin/git repack -n -a -d -f --depth=64 --window=300 --threads=0'
	fi
	/usr/bin/su gitclient -c '/usr/bin/git prune-packed'
	/usr/bin/su gitclient -c '/usr/bin/git fsck --strict --unreachable --dangling --full --cache'
	# git_action_stats
}
git_action_repack() {
	echo "### repack  #######################################################################"
	echo "---> $REPO/$LINE"
	cd $REPO/$LINE
	/usr/bin/su gitclient -c "sh /etc/action/.action-git-config.sh"
	/usr/bin/su gitclient -c '/usr/bin/git prune --expire=now'
	/usr/bin/su gitclient -c '/usr/bin/git reflog expire --expire-unreachable=now --rewrite --all'
	/usr/bin/su gitclient -c '/usr/bin/git pack-refs --all'
	/usr/bin/su gitclient -c '/usr/bin/git gc --aggressive --keep-largest-pack'
	/usr/bin/su gitclient -c '/usr/bin/git prune-packed'
}
git_action() {
	cd $REPO/$LINE
	/usr/bin/su gitclient -c "sh /etc/action/.action-git-config.sh"
	/usr/bin/su gitclient -c "git gc --auto"
	echo "## [done] $BSD_GIT/$LINE"
}
git_autoarchive() {
	echo "... check for git repos to .autoarchive!"
	ls -I $REPO | while read LINE; do
		SEARCH="^$LINE"
		if [ "$(grep $SEARCH $REPO/active)" == "" ] && [ -x $REPO/$LINE ]; then
			echo ""
			echo "### AUTOARCHIVE ---->>>>> $LINE ###"
			mkdir -p $REPO/.autoarchive
			git_action_rebuild
			cd $REPO
			tar -cf - $LINE | $COMPRESS > $REPO/.autoarchive/$LINE.git-deflate-tree.tar.zst
			chown gitclient:gitclient $REPO/.autoarchive/$LINE.git-deflate-tree.tar.zst
			chmod 644 $BSD_GIT/.autoarchive/$LINE.git-deflate-tree.tar.zst
			rm -rf $LINE
		fi
	done
}
git_autounarchive_all() {
	ls -I $REPO/.autoarchive | sed -e 's/\.git-deflate-tree\.tar\.zst//g' >> $REPO/active
}
git_autounarchive() {
	echo "... check for archives to un- .autoarchive!"
	cat $REPO/active | while read LINE; do
		TARGET=$REPO/.autoarchive/$LINE.git-deflate-tree.tar.zst
		if [ -e $TARGET ] && [ ! -x $REPO/$LINE ]; then
			echo ""
			echo "### AUTO-UN-ARCHIVE ---->>>>> $LINE ###"
			mkdir -p $REPO/$LINE && cd $REPO/$LINE
			tar -C $REPO -xf $TARGET
			mv $TARGET $BSD_EXCHANGE/$LINE.git-deflate-tree.tar.unpacked.$(date "+%Y%m%d%H%M%S")
			chown -R gitclient:gitclient $REPO/$LINE
			/usr/bin/su gitclient -c "sh /etc/action/.action-git-config.sh"
		fi
	done
}
git_repo_consolidate() {
	FILE=active
	cd $REPO
	cat $FILE | sort --uniq > $FILE.temp
	rm -f $FILE
	touch $FILE
	cat $FILE.temp | while read LINE; do
		if [ -x $REPO/$LINE ]; then
			echo $LINE >> $FILE
		elif [ -e $REPO/.autoarchive/$LINE.git-deflate-tree.tar.zst ]; then
			echo $LINE >> $FILE
		else
			echo "ERROR: $FILE -> entry $LINE removed, not an GIT [active|autoarchive] REPO!"
		fi
	done
	rm -f $FILE.temp
	chown gitclient:gitclient $FILE
	echo "... [done] rebuild & validated: $REPO/$FILE!"
}
###########################################################################
if [ $1 ]; then
	# single repo action, do, exit
	if [ -x $REPO/$1/.git ]; then
		LINE=$1
		cd $REPO/$LINE
		case $2 in
		rebuild)
			git_action_rebuild
			;;
		aggressive)
			git_action_aggressive
			;;
		repack) git_action_repack ;;
		sign) CHECKOUT=HEAD && if [ $3 ]; then CHECKOUT=$3; fi && git_action_sign ;;
		*) git_action ;;
		esac
		rm $LOCKFILE && sync && beep
		exit
	fi
	# re-eval all pending options
	unset XALL REPACK AGGRESSIVE
	case $1 in
	all) export XALL=true ;;
	repack) export REPACK=true ;;
	rebuild) export REBUILD=true ;;
	aggressive) export AGGRESSIVE=true ;;
	unarchiveall) git_autounarchive_all ;;
	*) echo " ... repo not found! Please specify a valid GIT repo!" && rm $LOCKFILE && exit ;;
	esac
	case $2 in
	all) export XALL=true ;;
	repack) export REPACK=true ;;
	aggressive) export AGGRESSIVE=true ;;
	rebuild) export REBUILD=true ;;
	unarchiveall) git_autounarchive_all ;;
	esac
	case $3 in
	all) export XALL=true ;;
	esac
fi
TREPO=$BSD_GIT
if [ "$XALL" = "true" ]; then TREPO=$BSD_GIT/.repo; fi
# single thread rebuild
if [ $REBUILD ]; then
	ls -I $TREPO | while read LINE; do
		if [ -d $REPO/$LINE ]; then git_action_rebuild; fi
	done
# single thread aggressive
elif [ $AGGRESSIVE ]; then
	ls -I $TREPO | while read LINE; do
		if [ -d $REPO/$LINE ]; then git_action_aggressive; fi
	done
# single thread repack
elif [ $REPACK ]; then
	ls -I $TREPO | while read LINE; do
		if [ -d $REPO/$LINE ]; then git_action_repack; fi
	done
# multithread for autogc / cleanup
else
	if [ "$XALL" = "true" ]; then
		git_repo_consolidate
		git_autounarchive
		git_autoarchive
	fi
	wait
	LIST=$(ls -I $TREPO)
	for LINE in $LIST; do
		if [ -d $REPO/$LINE ]; then
			git_action &
		fi
		jobs -lp > /var/.$PPID
		while [ $(cat /var/.$PPID | wc -l) -gt $PARALLEL ]; do
			sleep 0.1 && jobs -lp > /var/.$PPID
		done
		rm /var/.$PPID
	done
fi
wait
find . | grep FETCH_HEAD | xargs rm -rf
rm -f $LOCKFILE
sync && sync && sync
beep
exit
###########################################################################
