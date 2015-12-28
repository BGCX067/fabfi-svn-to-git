# portalgun: Mesh network access controller
#
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

# - configuration ----------------------------------------------------------
PKG_NAME:=fabfi-monitoring
PKG_VERSION:=0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

# -------------------------------------------------------------
define Package/fabfi-monitoring
	SECTION:=base
	CATEGORY:=Fabfi
	TITLE:=Map visualization, SNMPv3 and offline logging
	DEPENDS:=+fabfi-core +snmpd +snmp-utils +rrdtool +olsrd-mod-txtinfo 
	VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)
	URL:=http://fabfi.org
endef

define Package/fabfi-monitoring/description
	A collection of helper scripts and files necessary for setting up monitoring and visualization of a fabfi wireless mesh network.
endef

define Build/Compile
	# to be done 
endef

define Package/fabfi-monitoring/install
	$(INSTALL_DIR) $(1)/usr/bin/fabfi/
	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./scripts/* $(1)/usr/bin/fabfi/
	$(INSTALL_DATA) ./files/snmpd $(1)/etc/config/snmpd
	$(LN) /usr/bin/fabfi/setup-monitoring $(1)/etc/uci-defaults/99setup-monitoring
	
endef

define Package/fabfi-monitoring/postinst
#!/bin/sh
# check if we are on the real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	
	echo "*/1 * * * * /bin/ash /usr/bin/fabfi/copy-files.sh 2> /dev/null" >> /etc/crontabs/root
	echo "*/2 * * * * sh /usr/bin/fabfi/fabfimap.sh > /dev/null" >> /etc/crontabs/root
	echo "*/5 * * * * sh /usr/bin/fabfi/offline-log.sh > /dev/null" >> /etc/crontabs/root
	
	uci set snmpd.@system[0].sysName=`uci get system.@system[0].hostname`
	uci set snmpd.@system[0].sysLocation=`uci get system.@system[0].hostname`
	uci set snmpd.@system[0].sysContact=fabfi@fabfi.com
	uci commit	
fi
endef


# - eval packages ----------------------------------------------------------
$(eval $(call BuildPackage,fabfi-monitoring))

