#!/bin/sh
. /etc/.bsdconf
# commandline parameter
FINAL_IMG=$1
SOURCE_DIR=$2
FS=$3
COMPRESS=$4
LABEL=$5
EXTRA_ACTION=$6
# external helper
MAKEFS_CMD="/usr/bin/makefs"
MDCONFIG_CMD="/usr/bin/mdconfig -f"
UMDCONFIG_CMD="/usr/bin/mdconfig -d -u"
MKUZIP_CMD="/usr/bin/mkuzip"
MOUNT_CMD="/usr/bin/mount"
UMOUNT_CMD="/usr/bin/umount"
FIND_CMD="/usr/bin/find"
SQUASH_CMD="/usr/bin/gensquashfs"
UUIDGEN_CMD="/usr/bin/uuidgen"
CUT_CMD="/usr/bin/cut"
if [ $SOURCE_DIR_CLEANUP ]; then echo "[create.img] [*WARNING*] source-directory-cleanup explicit activated"; fi
ex() {
	echo "[c.img] $XCMD"
	if [ $DEBUG ]; then
		$XCMD
	else
		$XCMD > /dev/null 2>&1
	fi
}
syntax() {
	echo ""
	echo "syntax make.img <target.image> <source-directory> [optional:<filesystem> <compression> <fs-label> <extra_action>"
	exit
}
parse() {
	WORKING_DIR="/tmp/.$($UUIDGEN_CMD | $CUT_CMD -c 1-8)"
	TARGET_IMG="$WORKING_DIR/t.img"
	MOUNTPOINT="$WORKING_DIR/m"
	mkdir -p $MOUNTPOINT && touch $TARGET_IMG $FINAL_IMG
	if [ ! -e $TARGET_IMG ]; then echo "[error] [create,img] [unable to create TEMPORARY TARGET_IMG] [$TARGET_IMG]" && exit; fi
	if [ ! -e $FINAL_IMG ]; then echo "[error] [create.img] [unable to create FINAL_IMG] [$FINAL_IMG]" && exit; fi
	rm -rf $TARGET_IMG $FINAL_IMG
	if [ -z "$FINAL_IMG" ]; then echo "[error] [create,img] [please specify target img filename]" && syntax; fi
	if [ -z "$SOURCE_DIR" ]; then echo "[error] [create,img] [please specify source directory]" && syntax; fi
	if [ ! -x $SOURCE_DIR ]; then echo "[error] [create.img] [unable to access target directory] [$SOURCE_DIR]" && syntax; fi
	if [ -z "$LABEL" ]; then LABEL=$($UUIDGEN_CMD); fi
	if [ -z "$FS" ]; then FS=ffs; fi
	if [ -z "$COMPRESS" ]; then COMPRESS=zstd; fi
	case $FS in
	none) ;;
	squash*)
		if [ ! -x $SQUASH_CMD ]; then echo "gensquashfs [pkg:squashfs-tools-ng] not installed, exit " && exit; fi
		SQUASH_CMD="$SQUASH_CMD --pack-dir $SOURCE_DIR -o -f -j $(sysctl -n hw.ncpu)"
		;;
	msdos*)
		if [ ! -x $MAKEFS_CMD ]; then echo "makefs [pkg:freebsd-base] not installed, exit " && exit; fi
		if [ ! -x $MKUZIP_CMD ]; then echo "mkuzip [pkg:freebsd-base] not installed, exit " && exit; fi
		SIZE="$(($(df | grep $BOOTFS | awk '{print $3}') + 512))k"
		FSCK_CMD="/usr/bin/fsck_msdos -f"
		MOUNT_CMD="$MOUNT_CMD -t msdosfs"
		FSDD_CMD="" # disable hardlinks
		case $FS in
		msdos) MAKEFS_CMD="$MAKEFS_CMD -t msdos -T 0 -s $SIZE" ;;
		msdos12) MAKEFS_CMD="$MAKEFS_CMD -t msdos -o fat_type=12 -T 0 -s $SIZE" ;;
		msdos16) MAKEFS_CMD="$MAKEFS_CMD -t msdos -o fat_type=16 -T 0 -s $SIZE" ;;
		msdos32) MAKEFS_CMD="$MAKEFS_CMD -t msdos -o fat_type=32 -T 0 -s $SIZE" ;;
		*) echo "[error] [create.img] [unknown fs msdos definition] [$FS]" && exit ;;
		esac
		;;
	ffs*)
		if [ ! -x $MAKEFS_CMD ]; then echo "makefs [pkg:freebsd-base] not installed, exit " && exit; fi
		if [ ! -x $MKUZIP_CMD ]; then echo "mkuzip [pkg:freebsd-base] not installed, exit " && exit; fi
		FSCK_CMD="/usr/bin/fsck_ffs -fyEZzRr"
		MOUNT_CMD="$MOUNT_CMD -t ffs"
		case $FS in
		ffs | ffs1)
			MAKEFS_CMD="$MAKEFS_CMD -T 0 -t ffs -o version=1 -o softupdates=0 -o label=$LABEL"
			;;
		ffs2)
			MAKEFS_CMD="$MAKEFS_CMD -T 0 -t ffs -o version=2 -o softupdates=0 -o label=$LABEL"
			;;
		ffs3)
			MAKEFS_CMD="$MAKEFS_CMD -T 0 -t ffs -o version=2 -o softupdates=0 -o label=$LABEL"
			FSCK_CMD="/usr/bin/fsck_ffs -fyEZzRr -c 3" # destroys mtime/atime/btime T0 superblock
			;;
		*) echo "[error] [create.img] [unknown fs ffs definition] [$FS]" && exit ;;
		esac
		;;
	*) echo "[error] [unsupported filesystem] [$FS]" && exit ;;
	esac
	case $COMPRESS in
	zstd*)
		COMP="zstd" && EXT=".uzst"
		case $COMPRESS in
		zstd | zstd22) MKUZIP_CMD="$MKUZIP_CMD -A zstd -C 22 -s 131072 -d -S" ;;
		zstd14) MKUZIP_CMD="$MKUZIP_CMD -A zstd -C 14 -s 131072 -S" ;;
		zstd12) MKUZIP_CMD="$MKUZIP_CMD -A zstd -C 12 -s 131072 -S" ;;
		zstd0) MKUZIP_CMD="$MKUZIP_CMD -A zstd -s 131072 -S" ;;
		*) echo "[error] [create.img] [unknown zstd compression definition] [$COMPRESS]" && exit ;;
		esac
		;;
	lzma) COMP="lzma" && EXT=".ulzma" && MKUZIP_CMD="$MKUZIP_CMD -A lzma -C 9 -s 131072 -d -S" ;;
	none)
		EXT="" && TARGET_IMG=$FINAL_IMG
		case $FS in
		squash*) echo "[error] [create.img] [squashfs does not allow none] [$COMPRESS]" && exit ;;
		esac
		;;
	xz | gzip | lz4)
		COMP=$COMPRESS
		case $FS in
		ffs* | msdos*) echo "[error] [create.img] [not supported for ffs/msdos] [$COMPRESS]" && exit ;;
		esac
		;;
	*) echo "[error] [create.img] [unknown compression definition] [$COMPRESS]" && exit ;;
	esac
	MKUZIP_CMD="$MKUZIP_CMD -o $FINAL_IMG"
	FSDD_CMD="sh /etc/goo/goo.fsdd --hard-link --clean-metadata --fast-hash"
	case $EXTRA_ACTION in
	stripsource) if [ -x "$STRIPBIN" ]; then STRIP_CMD="$STRIPBIN"; fi ;;
	nofsck) FSCK_CMD="" ;;
	nodedupe) FSDD_CMD="" ;;
	nopost) FSCK_CMD="" && FSDD_CMD="" && STRIP_CMD="" ;;
	esac
}
action() {
	if [ -n "$STRIP_CMD" ]; then
		echo "[info] [create.img] [strip on source directory] [$SOURCE_DIR]"
		(cd $SOURCE_DIR && find . -type f -exec $STRIPBIN --strip-all {} \; > /dev/null 2>&1)
	fi
	if [ ! -z "$FSDD_CMD" ]; then
		XCMD="$FSDD_CMD $SOURCE_DIR" && ex
		XCMD="$FSDD_CMD $SOURCE_DIR" && ex
	fi
	case $FS in
	none | squash*) ;;
	ffs* | msdos*)
		XCMD="$MAKEFS_CMD $TARGET_IMG $SOURCE_DIR" && ex
		if [ ! -z "$FSCK_CMD" ]; then
			MD="$($MDCONFIG_CMD $TARGET_IMG)"
			DRIVE="/dev/$MD"
			FSCK="$FSCK_CMD $DRIVE"
			XCMD="$FSCK" && ex
			XCMD="$MOUNT_CMD $DRIVE $MOUNTPOINT" && ex
			if [ ! -z "$FSDD_CMD" ]; then
				XCMD="$FSDD_CMD $MOUNTPOINT" && ex
				XCMD="$FSDD_CMD $MOUNTPOINT" && ex
			fi
			XCMD="$UMOUNT_CMD $MOUNTPOINT" && ex
			XCMD="$FSCK" && ex
			XCMD="$UMDCONFIG_CMD $MD" && ex
		fi
		;;
	*) echo "[error] [unsupported filesystem] [$FS]" && exit ;;
	esac
	case $COMPRESS in
	none) ;;
	*)
		case $FS in
		squash*) XCMD="$SQUASH_CMD --compressor $COMP $FINAL_IMG" && ex ;;
		ffs* | msdos*)
			if [ $SOURCE_DIR_CLEANUP ]; then rm -rf $SOURCE_DIR; fi
			XCMD="$MKUZIP_CMD $TARGET_IMG" && ex && rm -rf $TARGET_IMG
			;;
		esac
		;;
	esac
	rm -rf $WORKING_DIR
	echo "[create.img] [out:$FINAL_IMG] "
}
parse
action
