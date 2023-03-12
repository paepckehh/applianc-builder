# OVERVIEW

[paepcke.de/appliance-builder](https://paepcke.de/appliance-builder) 

Cross Plattform FreeBSD Appliance Builder (Lab, not Prod!)

# CONFIGURE

Works best by booting an existing FreeBSD BSRV (Build Server) Image,
If not possible, manual bootstrap:

1. Configure 'appliance-builder/conf/etc/action/.bsdconf'
	- set at least BSD_STORE file path root
2. Configure Env
	- . appliance-builder/conf/etc/action/.bsdconf 
	- export PATH=$PATH:appliance-builder/bin
3. cd $BSD_SBC
	- create a sbc/workstation/server hardware definition
	- easy to configure via inherences, see existing examples
	- activate all covered active profiles via .active file
4. cd $BSD_DIST
	- create a distribution set (eg. packages/software needed)
	- easy to configure via inherences, see existing examples
	- activate all covered active profiles via .active file
5. Build all packages (native, cross-plattform) for all targets
	- BSDpkg cc  
	- opt: check appliance-builder/bin/action/.buildenv.sh for bootstrap toolchain
6. Build Appliance image
	- BSDbuild SBC DIST (Example: amd64 bsrv)
7. Write Appliance image
	- BSDwrite SBC DIST DEVICE (Example: amd64 bsrv da1)

# TODO

# DOCS

# CONTRIBUTION

Yes, Please! PRs Welcome! 
