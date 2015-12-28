# fabfi-portal: Mesh network access controller
#
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

# - configuration ----------------------------------------------------------
PKG_NAME:=fabfi-portal
PKG_REV:=0.01
PKG_VERSION:=1.0-r$(PKG_REV)
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

# - fabfi-portal -------------------------------------------------------------
define Package/fabfi-portal
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Captive Portals
	DEPENDS:=+villagebus-core +luamd5 +haproxy +ip6tables +iptables-mod-tproxy +kmod-ipt-tproxy
	TITLE:=Mesh network access controller
	VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)
	URL:=http://fabfi.org
endef

define Package/fabfi-portal/description
	Mesh network access controller
endef

define Build/Compile
	# TODO luac
endef

define Package/fabfi-portal/install
	$(INSTALL_DIR)  $(1)/usr/lib/lua/villagebus/modules
	$(INSTALL_DATA) ./fabfi-portal.lua  $(1)/usr/lib/lua/villagebus/modules
	$(INSTALL_DATA) ./splash.lua     $(1)/usr/lib/lua/villagebus/modules

	$(INSTALL_DIR)  $(1)/www/splash
	$(INSTALL_DATA) ./html/index.html $(1)/www/splash

	$(INSTALL_DIR)  $(1)/etc/init.d/
	$(INSTALL_BIN) ./init $(1)/etc/init.d/fabfi-portal
	$(INSTALL_BIN) ./haproxy-init $(1)/etc/init.d/haproxy

	$(INSTALL_DIR)  $(1)/etc/fabfi-portal/
	$(INSTALL_DATA) ./dictionary $(1)/etc/fabfi-portal/
endef

define Package/fabfi-portal/postinst
	#!/bin/sh
	# check if we are on the real system
	if [ -z "$${IPKG_INSTROOT}" ]; then
		touch /etc/fabfi-portal.postinst.test

		/sbin/uci add lucid splashroot
		/sbin/uci set lucid.splashroot="VillagebusPublisher"
		/sbin/uci set lucid.splashroot.name="splash"
		/sbin/uci set lucid.splashroot.home=1
		/sbin/uci set lucid.splashroot.physical="/splash"

		/sbin/uci add lucid splash
		/sbin/uci set lucid.splash="daemon"
		/sbin/uci set lucid.splash.slave="httpd"
		/sbin/uci set lucid.splash.address=8001
		/sbin/uci set lucid.splash.nokeepalive=1
		/sbin/uci set lucid.splash.memlimit=1572864
		/sbin/uci set lucid.splash.enabled=1
		/sbin/uci add_list lucid.splash.publisher="splashroot"

		  uci commit
	fi
endef


# - eval packages ----------------------------------------------------------
$(eval $(call BuildPackage,fabfi-portal))

