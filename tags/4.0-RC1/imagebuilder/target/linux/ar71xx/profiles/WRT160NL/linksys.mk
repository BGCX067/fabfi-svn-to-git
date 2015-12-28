#
# Copyright (C) 2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/WRT160NL
	NAME:=Linksys WRT160NL
	FILES:=fabfi
	PACKAGES:=kmod-ath9k kmod-mac80211 wpad-mini kmod-usb-core -kmod-madwifi kmod-usb2 swconfig \
libuci bridge \
kmod-scsi-core kmod-usb-storage kmod-fs-ext3 e2fsprogs block-extroot fdisk block-mount \
kmod-gpio-dev kmod-input-core kmod-input-gpio-buttons kmod-input-polldev kmod-leds-gpio \
olsrd olsrd-mod-nameservice olsrd-mod-txtinfo olsrd-mod-dyn-gw \
mini-httpd netcat \
kmod-tun \
libopenssl libpthread squid \
mini-snmpd \
uclibcxx iperf \
libpcap tcpdump \
awesome-chilli libjson \
-ppp -ppp-mod-pppoe -kmod-ppp -kmod-pppoe -kmod-crc-ccitt -uhttpd \
nagios nagios-plugins send-nsca libmcrypt libwrap nrpe

endef

define Profile/WRT160NL/Description
	Package set optimized for the Linksys WRT160NL.
endef

define Profile/WRT400N
	NAME:=Linksys WRT400N
	PACKAGES:=kmod-ath9k wpad-mini
endef

define Profile/WRT400N/Description
	Package set optimized for the Linksys WRT400N.
endef

$(eval $(call Profile,WRT160NL))
$(eval $(call Profile,WRT400N))
