#!/bin/sh
####################################
### EXTERNAL FUNCTIONS INTERFACE ###
####################################
build_crypto() {
	cd $ROOTFS/usr/sbin
	FBSD_LIBMD_SKIPLIST="sha1 sha224 sha256 sha384 sha512 sha512t256 md4 md5 skein256 skein512 skein1024"
	echo "... faster implementations will automatically replace slower!"
	echo "... low overhead basline libmd stays in /bin as default!"
	if [ -e ../bin/hasher ] && [ "$BSD_DIST_DGST_WRAPPER" = "all" ]; then
		if [ "$TARGETARCH" = $(uname -m) ]; then
			echo "### EXTENDED GOHASH ADDITIONS UNLOCKED [ DYNAMIC UPDATE ] ###"
			DGST_LIST=$(./../bin/hasher -A | sed -e 's/\[//g' | sed -e 's/\]//g')
		else
			echo "### EXTENDED GOHASH ADDITIONS UNLOCKED [ STATIC CROSS COMPILER FALLBACK ] ###"
			DGST_LIST="adler adler32 blake224 blake256 blake2b blake2b-256 blake2b-512 blake2s blake2s-256 blake3 blake3-224 blake3-256 blake3-384 blake3-512 blake384 blake512 crc16-ccitt crc16-ccitt-false crc16-ibm crc16-scsi crc24-openpgp crc32 crc32-castagnoli crc32-ieee crc32-koopman crc32c crc32k crc64 crc64-ecma crc64-iso crc8-atm fnv1-32 fnv1-64 fnv1a-32 fnv1a-64 gost gost94 gost94-cryptopro md2 md4 md5 ripemd160 sha1 sha224 sha256 sha3 sha3-224 sha3-256 sha3-384 sha3-512 sha384 sha512 sha512-224 sha512-256 sha512t256 shake128-256 shake256-512 siphash siphash-2-4 skein skein256 skein512 skein512-256 skein512-512 sm3 streebog-256 streebog-512 streebog2012-256 streebog2012-512 tiger tiger192 whirlpool xxhash xxhash64"
		fi
		for DGST in $DGST_LIST; do
			echo "#!/bin/sh" > $DGST
			echo if [ '$1' ]"; then" >> $DGST
			echo "	"hasher --no-colors --skip-filename "$DGST" -i '$1' >> $DGST
			echo else >> $DGST
			echo "	"hasher --no-colors --skip-filename "$DGST" >> $DGST
			echo fi >> $DGST
			chmod +x $DGST
		done
	fi
	if [ -e ../bin/openssl ]; then
		echo "### COMMON SHARED OPENSSL BASE LINE ###"
		echo 'openssl rmd160	 $1 | tail -c 33' > rmd160
		chmod +x rmd160
		echo 'openssl md4	 $1 | tail -c 33' > md4
		chmod +x md4
		echo 'openssl md5	 $1 | tail -c 33' > md5
		chmod +x md5
		echo 'openssl sha1	 $1 | tail -c 33' > sha1
		chmod +x sha1
		echo 'openssl sha224	 $1 | tail -c 57' > sha224
		chmod +x sha224
		echo 'openssl sha256	 $1 | tail -c 65' > sha256
		chmod +x sha256
		echo 'openssl sha384	 $1 | tail -c 97' > sha384
		chmod +x sha384
		echo 'openssl sha512 	 $1 | tail -c 129' > sha512
		chmod +x sha512
		echo 'openssl sm3 	 $1 | tail -c 65' > sm3
		chmod +x sm3
		echo 'openssl whirlpool2 $1 | tail -c 129' > whirlpool
		chmod +x whirlpool
		echo 'openssl enc -e -a -A $1' > base64encode
		chmod +x base64encode
		echo 'openssl enc -d -a -A $1' > base64decode
		chmod +x base64decode
		if [ -n "$(strings -a ../bin/openssl | grep 'LockSSL 3')" ]; then
			echo "### LockSSL ONLY"
			echo 'openssl streebog256 $1 | tail -c 65' > streebog-256
			chmod +x streebog-256
			echo 'openssl streebog256 $1 | tail -c 65' > gost2012-256
			chmod +x gost2012-256
			echo 'openssl streebog512 $1 | tail -c 129' > streebog-512
			chmod +x streebog-512
			echo 'openssl streebog512 $1 | tail -c 129' > gost2012-512
			chmod +x gost2012-512
		elif [ -n "$(strings -a ../bin/openssl | grep 'Libre 3')" ]; then
			echo "### LibreSSL ONLY"
			echo 'openssl md_gost94	 $1 | tail -c 65' > gost94
			chmod +x gost94
			echo 'openssl md_gost94	 $1 | tail -c 65' > gost
			chmod +x gost
			echo 'openssl streebog256 $1 | tail -c 65' > streebog-256
			chmod +x streebog-256
			echo 'openssl streebog256 $1 | tail -c 65' > gost2012-256
			chmod +x gost2012-256
			echo 'openssl streebog512 $1 | tail -c 129' > streebog-512
			chmod +x streebog-512
			echo 'openssl streebog512 $1 | tail -c 129' > gost2012-512
			chmod +x gost2012-512
		elif [ -n "$(strings -a ../bin/openssl | grep 'OpenSSL 1.1.1')" ]; then
			echo "### OpenSSL 1.1.1 branch"
			echo 'openssl md5-sha1	 $1 | tail -c 66' > md5-sha1
			chmod +x md5-sha1
			echo 'openssl blake2b512 $1 | tail -c 128' > blake2b-512
			chmod +x blake2b-512
			echo 'openssl blake2s256 $1 | tail -c 65' > blake2s-256
			chmod +x blake2s-256
			echo 'openssl sha3  	 $1 | tail -c 129' > sha3
			chmod +x sha3
			echo 'openssl sha3-224   $1 | tail -c 57' > sha3-224
			chmod +x sha3-224
			echo 'openssl sha3-256   $1 | tail -c 65' > sha3-256
			chmod +x sha3-256
			echo 'openssl sha3-384   $1 | tail -c 97' > sha3-384
			chmod +x sha3-384
			echo 'openssl sha3-512   $1 | tail -c 129' > sha3-512
			chmod +x sha3-512
			echo 'openssl shake128   $1 | tail -c 65' > shake128-256
			chmod +x shake128-256
			echo 'openssl shake256   $1 | tail -c 129' > shake256-512
			chmod +x shake256-512
			echo 'openssl sha512-224 $1 | tail -c 57' > sha512-224
			chmod +x sha512-224
			echo 'openssl sha512-256 $1 | tail -c 65' > sha512-256
			chmod +x sha512-256
			echo 'openssl sha512-256 $1 | tail -c 65' > sha512t256
			chmod +x sha512t256
		fi
	fi

}
