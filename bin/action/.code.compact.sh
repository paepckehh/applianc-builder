#!/bin/sh
if [ ! $1 ]; then echo "[code.compact] [error] [missing path] [exit]" && exit 1; fi
if [ ! $BSD_CONF_VERSION ]; then . /etc/.bsdconf; fi
opt="--silent --inplace"
if [ $2 ]; then opt="$opt --exclude $2"; fi
if [ $3 ]; then opt="$opt --exclude $3"; fi
if [ $4 ]; then opt="$opt --exclude $4"; fi
if [ $C_ONLY ]; then opt="$opt --disable-sh --disable-make --disable-go"; fi
if [ $C_SH_ONLY ]; then opt="$opt --disable-go --disable-make"; fi
if [ $C_SH_MAKE_ONLY ]; then opt="$opt --disable-go"; fi
if [ $C_MAKE_ONLY ]; then opt="$opt --disable-go --disable-sh --disable-make"; fi
if [ $GO_ONLY ]; then opt="$opt --disable-sh --disable-c --disable-make"; fi
if [ $SH_ONLY ]; then opt="$opt --disable-go --disable-c --disable-make"; fi
if [ $DISABLE_ASM ]; then opt="$opt --disable-asm"; fi
if [ $DISABLE_GO ]; then opt="$opt --disable-go"; fi
if [ $DISABLE_C ]; then opt="$opt --disable-c"; fi
if [ $DISABLE_MAKE ]; then opt="$opt --disable-make"; fi
if [ $DISABLE_SH ]; then opt="$opt --disable-sh"; fi
if [ $DISABLE_HIDDEN ]; then opt="$opt --disable-hidden-files"; fi
unset GOGC
sh /etc/goo/goo.codereview $1 $opt
sh /etc/goo/goo.fsdd --hard-link --fast-hash $1
