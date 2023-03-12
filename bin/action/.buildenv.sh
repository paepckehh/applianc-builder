#!/bin/sh
export LINKER_BASELINE="build-id ifunc riscv-relaxations retpoline ifunc-noplt"
export COMPILER_BASELINE="c++20 c++17 c++14 c++11 retpoline init-all fileprefixmap aarch64-sha512"
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
buildenv_activate_llvm16() {
	BSDlive llvm16
	buildenv_conf_llvm16
}
buildenv_activate_llvm15() {
	BSDlive llvm15
	buildenv_conf_llvm15
}
buildenv_activate_llvm14() {
	BSDlive llvm14
	buildenv_conf_llvm14
}
buildenv_activate_llvm13() {
	BSDlive llvm13
	buildenv_conf_llvm13
}
buildenv_conf_llvm16() {
	export LLVM_BASE=16
	export LINKER_FEATURES=$LINKER_BASELINE
	export COMPILER_FEATURES=$COMPILER_BASELINE
	buildenv_conf_llvm
}
buildenv_conf_llvm15() {
	export LLVM_BASE=15
	export LINKER_FEATURES=$LINKER_BASELINE
	export COMPILER_FEATURES=$COMPILER_BASELINE
	buildenv_conf_llvm
}
buildenv_conf_llvm14() {
	export LLVM_BASE=14
	export LINKER_FEATURES=$LINKER_BASELINE
	export COMPILER_FEATURES=$COMPILER_BASELINE
	buildenv_conf_llvm
}
buildenv_conf_llvm13() {
	export LLVM_BASE=13
	export LINKER_FEATURES=$LINKER_BASELINE
	export COMPILER_FEATURES=$COMPILER_BASELINE
	buildenv_conf_llvm
}
buildenv_conf_bsd_elftoolchain() {
	export TOOLCHAIN="fbsd elf toolchain"
	export AS=/usr/bin/as
	export AR=/usr/bin/ar
	export NM=/usr/bin/nm
	export OBJDUMP=/usr/bin/objdump
	export OBJCOPY=/usr/bin/objcopy
	export STRINGS=/usr/bin/strings
	export STRIPBIN=/usr/bin/strip
	export RANLIB=/usr/bin/ranlib
	export SIZE=/usr/bin/size
	export ELFCTL=/usr/bin/elfctl
	export INSTALL=/usr/bin/install
	export CROSS_BINUTILS_PREFIX="/var/empty"
	buildenv_conf_toolchain
}
##################################
### INTERNAL FUNCTIONS BACKEND ###
##################################
buildenv_conf_llvm() {
	BASE=/usr/local/llvm$LLVM_BASE && CBIN=$BASE/bin
	export LLVM_VERSION_STRING="$(ls $BASE/lib/clang)" # eq. llvm-config --version (but faster)
	export LLVM_VERSION=$(echo $LLVM_VERSION_STRING | sed 's/\./0/g')
	export COMPILER_RESOURCE_DIR="$BASE/lib/clang/$LLVM_VERSION_STRING"
	export COMPILER_TYPE=clang
	export COMPILER_BASE=$LLVM_BASE
	export COMPILER_VERSION=$LLVM_VERSION
	export LINKER_TYPE=lld
	export LINKER_BASE=$LLVM_BASE
	export LINKER_VERSION=$LLVM_VERSION
	export CC=$CBIN/clang-$LLVM_BASE
	export CXX=$CBIN/clang++
	export CPP=$CBIN/clang-cpp
	export LD=$CBIN/ld.lld
	export LD_BASE=$LD
	export LINK=$CBIN/llvm-link
	export LLVM_LINK=$LINK
	export AS=$CBIN/llvm-as
	export AR=$CBIN/llvm-ar
	export NM=$CBIN/llvm-nm
	export OBJDUMP=$CBIN/llvm-objdump
	export OBJCOPY=$CBIN/llvm-objcopy
	export OBJCOPY_BASE=/usr/bin/objcopy
	export STRINGS=$CBIN/llvm-strings
	export RANLIB=$CBIN/llvm-ranlib
	export SIZE=$CBIN/llvm-size
	export STRIPBIN=$CBIN/llvm-strip
	export ELFCTL=/usr/bin/elfctl
	export X_COMPILER_TYPE=$COMPILER_TYPE
	export X_COMPILER_BASE=$COMPILER_BASE
	export X_COMPILER_VERSION=$COMPILER_VERSION
	export X_COMPILER_FEATURES=$COMPILER_FEATURES
	export X_COMPILER_RESOURCE_DIR=$COMPILER_RESOURCE_DIR
	export X_LINKER_TYPE=$LINKER_TYPE
	export X_LINKER_BASE=$LINKER_BASE
	export X_LINKER_VERSION=$LINKER_VERSION
	export X_LINKER_FEATURES=$LINKER_FEATURES
	export XCC=$CC
	export XCXX=$CXX
	export XCPP=$CPP
	export XLD=$LD
	export XLINK=$LINK
	export XLLVM_LINK=$LLVM_LINK
	export XAS=$AS
	export XAR=$AR
	export XNM=$NM
	export XOBJDUMP=$OBJDUMP
	export XOBJCOPY=$OBJCOPY
	export XSTRINGS=$STRINGS
	export XRANLIB=$RANLIB
	export XSIZE=$SIZE
	export XSTRIPBIN=$STRIPBIN
	export XELFCTL=$ELFCTL
	export XINSTALL=$INSTALL
	export CROSS_BINUTILS_PREFIX="/var/empty"
	if [ -x /usr/bin/ccache ]; then
		unset CCACHE_DISABLE CCACHE_DEBUG
		export CCACHE_COMPILERCHECK=none
		export CCACHE_INODECACHE=true
		export CCACHE_BIN=/usr/bin/ccache
		export CCACHE_PROGRAM=$CCACHE_BIN
		export CCACHE_BASEDIR=/usr/ccache
		export CCACHE_TEMPDIR=/usr/ccache/.temp
		export CCACHE_NOCOMPRESS=true
		export CCACHE_MAXSIZE=10G
		export CCACHE_SLOPPINESS="locale,time_macros"
		export CCACHE_COMPILER=$CC
		export CCACHE_COMPILERTYPE=$COMPILER_TYPE
	fi
	echo "### BUILDENV [LLVM$LLVM_VERSION_STRING] [$CCACHE_BIN] ### ACTIVATED! ###"
}
buildenv_conf_toolchain() {
	export XAS=$AS
	export XAR=$AR
	export XNM=$NM
	export XOBJDUP=$OBJDUP
	export XOBJCOPY=$OBJCOPY
	export XSTRIPBIN=$STRIPBIN
	export XSTRINGS=$STRINGS
	export XRANLIB=$RANLIB
	export XSIZE=$SIZE
	export XELFCTL=$ELFCTL
	export XINSTALL=$INSTALL
	export CROSS_BINUTILS_PREFIX="/var/empty"
	unset LD XLD LINK XLINK LLVM_LINK
	echo "### [$TOOLCHAIN] ELF binutils OS [built-in|native] toolchain activated ######################"
}
