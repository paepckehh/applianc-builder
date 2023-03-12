#!/bin/sh
. /etc/action/.check.store
BSDlive fossil
REPOS=$(ls -I $BSD_FOSSIL | grep "\.fossil")
REVIEW=/var/log.fossil.review.$(date "+%Y%m%d-%H%M%S").log
if [ -e fossil.fossil.zstd ]; then
	unzstd fossil.fossil.zstd
	PACK=true
fi
case $1 in
config)
	fossil settings ssl-ca-location "/.pnoc/apconf/catrust/rootCA.pem" --global
	fossil settings proxy "http://127.0.0.1:55999" --global
	exit
	;;
rebuild | repack)
	fossil rebuild $FOSSIL/fossil.fossil
	exit
	;;
esac
for REPO in $REPOS; do
	fossil sync --verbose --ipv4 -R $BSD_FOSSIL/$REPO
	echo "... [done] fossil sync -R $REPO"
done
echo "Commit:   0000000000000000000000000000000000000000000000000000000000000000" > $REVIEW
echo "$(date)" >> $REVIEW
echo "" >> $REVIEW
for REPO in $REPOS; do
	echo "########################################################################################" >> $REVIEW
	echo "############### FOSSIL REPO: $REPO " >> $REVIEW
	echo "########################################################################################" >> $REVIEW
	echo "" >> $REVIEW
	fossil timeline --full -v --limit 5 -R $BSD_FOSSIL/$REPO >> $REVIEW
	echo "" >> $REVIEW
	echo "... [done] fossil timeline --full -v --limit 5  -R $REPO"
done
if [ "$PACK" = "true" ]; then
	zstd -22 --ultra --long fossil.fossil &
fi
vim $REVIEW
wait
