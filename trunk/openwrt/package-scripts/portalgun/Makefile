# portalgun: Mesh network access controller
#
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

# - configuration ----------------------------------------------------------
PKG_NAME:=portalgun
PKG_REV:=1076
PKG_VERSION:=1.0-r$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_URL:=http://fabfi.googlecode.com/svn/trunk/src/portalgun/

# - sources ----------------------------------------------------------------
PKG_SOURCE_PROTO:=svn
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(if $(PKG_BRANCH),$(PKG_BRANCH),$(PKG_NAME))-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)


include $(INCLUDE_DIR)/package.mk

# - portalgun -------------------------------------------------------------
define Package/portalgun
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Captive Portals
	DEPENDS:=+villagebus-core +luamd5 +haproxy +ip6tables +iptables-mod-tproxy +kmod-ipt-tproxy +openssl-util
	TITLE:=Mesh network access controller
	VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)
	URL:=http://fabfi.org
endef

define Package/portalgun/description
	Mesh network access controller
endef

define Build/Compile
	# TODO luac
endef

define Package/portalgun/install
	$(INSTALL_DIR)  $(1)/usr/lib/lua/villagebus/modules
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/villagebus/modules/portalgun.lua  $(1)/usr/lib/lua/villagebus/modules
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/villagebus/modules/splash.lua     $(1)/usr/lib/lua/villagebus/modules

	$(INSTALL_DIR)  $(1)/www/splash
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/html/index.html $(1)/www/splash
endef

define Package/portalgun/postinst
#!/bin/sh
# check if we are on the real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	touch /etc/portalgun.postinst.test

  uci add lucid splashroot
  uci set lucid.splashroot="VillagebusPublisher"
  uci set lucid.splashroot.name="portalgun splash"
  uci set lucid.splashroot.home=1
  uci set lucid.splashroot.physical="/splash"

  uci add lucid splash
  uci set lucid.splash="daemon"
  uci set lucid.splash.slave="httpd"
  uci set lucid.splash.address=8001
  uci set lucid.splash.nokeepalive=1
  uci set lucid.splash.memlimit=1572864
  uci set lucid.splash.enabled=1
	uci add_list lucid.splash.publisher="splashroot"

  uci commit
fi
endef


# - eval packages ----------------------------------------------------------
$(eval $(call BuildPackage,portalgun))

