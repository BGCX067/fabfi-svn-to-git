#
# Copyright (C) 2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/UBNTNANOM
  NAME:=ubiquiti NanostationM
  FILES:=fabfi
## Assuming the following are automatically added
# base-files busybox dnsmasq dropbear firewall hotplug2 iptables kmod-diag kmod-ipt-nathelper kmod-switch
# libc libgcc mtd nvram opkg ppp ppp-mod-pppoe uci udevtrigger wpad-mini 
#
## Order of Package files
# USB
# Wireless
# Firewall stuff
# Fabfi crap...

  PACKAGES:=kmod-ath kmod-ath9k kmod-mac80211 -kmod-madwifi libnl-tiny crda wpad-mini \
libuci bridge \
olsrd olsrd-mod-nameservice olsrd-mod-txtinfo olsrd-mod-dyn-gw \
awesome-chilli kmod-tun ip \
mini-httpd netcat \
libpcap tcpdump \
libopenssl libpthread \
uclibcxx iperf \
snmpd \
libmcrypt libwrap vnstat vnstati iftop libjpeg libgd libpng \
snmp-utils \
libnetsnmp rrdtool libart \
libfreetype librrd \
kmod-gpio-dev kmod-button-hotplug kmod-input-core kmod-input-gpio-buttons kmod-input-polldev kmod-leds-gpio \
-kmod-usb-core -kmod-usb-ohci -kmod-usb2 -kmod-scsi-core -kmod-usb-storage -kmod-fs-ext3 -e2fsprogs -block-extroot -block-mount -kmod-fs-mbcache \
-ppp -ppp-mod-pppoe -kmod-ppp -kmod-pppoe -kmod-crc-ccitt -uhttpd \
-squid


#libpcap tcpdump \ uclibcxx iperf \ gpioctl \

#kmod-usb-core kmod-usb-ohci kmod-usb2 kmod-scsi-core kmod-usb-storage block-extroot \
#	crda iw kmod-b43 kmod-b43legacy kmod-cfg80211 kmod-mac80211 wireless-tools libnl-tiny \
#	libiptc libxtables kmod-ipt-conntrack kmod-ipt-core iptables-mod-conntrack iptables-mod-nat kmod-ipt-nat luci \
	


endef

define Profile/UBNTNANOM/Description
	Package set optimized for the NANO and PICO M series Fabfis
endef
$(eval $(call Profile,UBNTNANOM))


define Profile/UBNTRS
	NAME:=Ubiquiti RouterStation
	PACKAGES:=kmod-usb-core kmod-usb-ohci kmod-usb2
endef

define Profile/UBNTRS/Description
	Package set optimized for the Ubiquiti RouterStation.
endef

$(eval $(call Profile,UBNTRS))

define Profile/UBNTRSPRO
	NAME:=Ubiquiti RouterStation Pro
	PACKAGES:=kmod-usb-core kmod-usb-ohci kmod-usb2
endef

define Profile/UBNTRSPRO/Description
	Package set optimized for the Ubiquiti RouterStation Pro.
endef

$(eval $(call Profile,UBNTRSPRO))

define Profile/UBNT
	NAME:=Ubiquiti Products
	PACKAGES:=kmod-usb-core kmod-usb-ohci kmod-usb2
endef

define Profile/UBNT/Description
	Build images for all Ubiquiti products (including LS-SR71, RouterStation and RouterStation Pro)
endef

$(eval $(call Profile,UBNT))
