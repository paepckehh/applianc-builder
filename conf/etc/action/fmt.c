#!/bin/sh
if [ ! -x /usr/local/llvm/bin/clang ]; then BSDlive llvm; fi
if [ $1 ]; then
	/usr/local/llvm/bin/clang-format -i $*
else
	/usr/local/llvm/bin/clang-format -i *
fi
