#!/bin/sh
####################################
### CONFIGURATION SETUP SECTION  ###
####################################
review_config() {
	if [ ! -x $BSD_GIT ]; then echo "... git store not mounted!" && exit; fi
	export OUT=/var/tmp/git.changelog.$(date "+%Y%m%d%H%M%S")
	case $(uname -m) in
	amd64 | arm64) PARALLEL=$(($(/usr/bin/sysctl -n hw.ncpu) * 2)) ;;
	*) PARALLEL=$(/usr/bin/sysctl -n hw.ncpu) ;;
	esac
	unset FULL ISSUES PR
}
####################################
### INTERNAL FUNCTIONS INTERFACE ###
####################################
review_action() {
	if [ -e $BSD_GIT/.repo/$LINE/.git/config ]; then
		cd $BSD_GIT/.repo/$LINE
		GITHUB=$(cat .git/config | grep -c github)
		if [ $FULL ]; then
			GIT_LOG_CMD="doasgit log -c --since=yesterday --pretty=fuller --source"
		else
			GIT_LOG_CMD="doasgit log -c --since=yesterday --stat --decorate=short"
		fi
		if [ -e $BSD_GIT/.review.target/$LINE ]; then
			FOLLOW="$(cat $BSD_GIT/.review.target/$LINE)"
			echo "######################################################################################" >> $OUT.$LINE.log
			echo "########### $BSD_GIT/$LINE @ $FOLLOW" >> $OUT.$LINE.log
			PAGER=cat $GIT_LOG_CMD $FOLLOW >> $OUT.$LINE.log
			echo "## [done] $GIT_LOG_CMD --> $LINE @ $FOLLOW"
		fi
		echo "######################################################################################" >> $OUT.$LINE.log
		echo "########### $BSD_GIT/.repo/$LINE [HEAD]" >> $OUT.$LINE.log
		PAGER=cat $GIT_LOG_CMD $FOLLOW >> $OUT.$LINE.log
		echo "## [done] $GIT_LOG_CMD --> $LINE"
		if [ $ISSUE ] && [ $GITHUB -gt 0 ] && [ $GITHUB_TOKEN ]; then
			echo "########### GITHUB ISSUES: $BSD_GIT/$LINE " >> $OUT.$LINE.log
			gh issue list >> $OUT.$LINE.log 2>&1
			echo "## [done] gh issue list		--> $LINE"
			# hub issue list >>$OUT.$LINE.log 2>&1
			# echo "## [done] hub issue list		--> $LINE"
		fi
		if [ $PR ] && [ $GITHUB -gt 0 ] && [ $GITHUB_TOKEN ]; then
			echo "########### GITHUB PR: $BSD_GIT/$LINE " >> $OUT.$LINE.log
			gh pr list >> $OUT.$LINE.log 2>&1p
			echo "## [done] gh pr list		--> $LINE"
			# hub pr list >>$OUT.$LINE.log 2>&1
			# echo "## [done] hub pr list		--> $LINE"
		fi
	fi
}
####################################
###  EXTERNAL COMMAND INTERFACE  ###
####################################
review_config
case $1 in
all) export XALL=true ;;
full | "-c") export FULL=true ;;
issue) export ISSUE=true ;;
pr) export PR=true ;;
esac
case $2 in
all) export XALL=true ;;
full | "-c") export FULL=true ;;
issue) export ISSUE=true ;;
pr) export PR=true ;;
esac
case $3 in
all) export XALL=true ;;
full | "-c") export FULL=true ;;
issue) export ISSUE=true ;;
pr) export PR=true ;;
esac
if [ $ISSUE ] || [ $PR ]; then
	if [ ! $GITHUB_TOKEN ]; then echo "... please set GITHUB_TOKEN for ISSUEs/PRs github access!" && exit; fi
	if [ ! -x /usr/local/gh ]; then BSDlive cli; fi
	export HTTPS_PROXY="127.0.0.80:8080"
	export SSL_CERT_FILE="/etc/ssl/rootCA.pem"
fi
if [ $1 ] && [ -x $BSD_GIT/.repo/$1 ]; then
	export LINE=$1
	echo "commit 0000000000000000000000000000000000000000A" > $OUT.$LINE.log
	echo "$(date)" >> $OUT.$LINE.log
	review_action
	vim $OUT.$LINE.log
	exit
fi
TREPO="$BSD_GIT"
if [ "$XALL" = "true" ]; then TREPO="$BSD_GIT/.repo"; fi
cd $TREPO && LIST="$(ls -I)"
for LINE in $LIST; do
	review_action &
	jobs -lp > /var/tmp/.$PPID
	while [ $(cat /var/tmp/.$PPID | wc -l) -gt $PARALLEL ]; do
		sleep 0.1 && jobs -lp > /var/tmp/.$PPID
	done
	rm -rf /var/tmp/.$PPID
done
wait
echo "commit 0000000000000000000000000000000000000000" > $OUT
echo "$(date)" >> $OUT
cat $OUT.* >> $OUT
rm $OUT.*
echo "##############################################################" >> $OUT
echo "##############################################################"
/usr/bin/vim $OUT
exit
###########################################################################
