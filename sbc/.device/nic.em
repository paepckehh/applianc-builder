#!/bin/sh
export BSD_KERNCONF_DEVICE_NIC="$BSD_KERNCONF_DEVICE_NIC em iflib ether"
export BSD_KERNCONF_OPTIONS_NIC="$BSD_KERNCONF_OPTIONS_NIC TCP_OFFLOAD"
export NIC_PRIMARY="em0"
#XXX see $ENHANCED [wrong description, default, runtime driver crash]
#X='
#dev.em.0.eee_control=0'
#export BSD_SYSCTL="$BSD_SYSCTL$X" 
