#
# Copyright (C) 2008 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/WRT54GL
  NAME:=LINKSYS WRT54GL
  FILES:=fabfi/wrt54gl/
## Assuming the following are automatically added
# base-files busybox dnsmasq dropbear firewall hotplug2 iptables kmod-diag kmod-ipt-nathelper kmod-switch
# libc libgcc mtd nvram opkg ppp ppp-mod-pppoe uci udevtrigger wpad-mini 
#
## Order of Package files
# USB
# Wireless
# Firewall stuff
# Fabfi crap...

  PACKAGES:=kmod-b43 libuci bridge luci-ssl luci-app-firewall luci-app-qos mini-snmpd coova-chilli olsrd olsrd-mod-nameservice olsrd-mod-txtinfo olsrd-mod-dyn-gw -kmod-usb-core -kmod-usb-ohci -kmod-usb2 -kmod-scsi-core -kmod-usb-storage -kmod-fs-ext3 -kmod-fs-ext2 -e2fsprogs -kmod-b43legacy -ppp -ppp-mod-pppoe -kmod-ppp -kmod-pppoe -kmod-crc-ccitt
#kmod-usb-core kmod-usb-ohci kmod-usb2 kmod-scsi-core kmod-usb-storage block-extroot \
#	crda iw kmod-b43 kmod-b43legacy kmod-cfg80211 kmod-mac80211 wireless-tools libnl-tiny \
#	libiptc libxtables kmod-ipt-conntrack kmod-ipt-core iptables-mod-conntrack iptables-mod-nat kmod-ipt-nat luci \
	


endef

define Profile/WRT54GL/Description
	Package set optimized for linksys wrt54gl with b43 wireless
endef
$(eval $(call Profile,WRT54GL))
