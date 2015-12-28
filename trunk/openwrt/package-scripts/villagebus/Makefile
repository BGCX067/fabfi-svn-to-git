# villagebus: REST dispatch for mesh networks
#
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

# - configuration ----------------------------------------------------------
PKG_NAME:=villagebus
PKG_REV:=1076
PKG_VERSION:=1.0-r$(PKG_REV)
PKG_RELEASE:=1
PKG_SOURCE_URL:=http://fabfi.googlecode.com/svn/trunk/src/villagebus/

# - sources ----------------------------------------------------------------
PKG_SOURCE_PROTO:=svn
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(if $(PKG_BRANCH),$(PKG_BRANCH),$(PKG_NAME))-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

include $(INCLUDE_DIR)/package.mk

# - villagebus -------------------------------------------------------------
define Package/villagebus-core
	SECTION:=net
	CATEGORY:=Network
	DEPENDS:=+luci-lib-lucid-http +luci-lib-px5g +lualogging +luajson +luasocket
	TITLE:=REST dispatch for mesh networks
	VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)
	URL:=http://fabfi.org
endef

define Package/villagebus-core/description
	Core villagebus distribution
endef

define Build/Compile
	# TODO luac
endef

define Package/villagebus-core/install
	$(INSTALL_DIR)  $(1)/usr/lib/lua/villagebus
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/urlcode.lua     $(1)/usr/lib/lua/villagebus
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dispatcher.lua  $(1)/usr/lib/lua/villagebus

	$(INSTALL_DIR)  $(1)/usr/lib/lua/villagebus/modules
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/modules/http.lua  $(1)/usr/lib/lua/villagebus/modules

	$(INSTALL_DIR)  $(1)/usr/lib/lua/luci/lucid/http
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/lucid/VillagebusPublisher.lua  $(1)/usr/lib/lua/luci/lucid/http

	$(INSTALL_DIR)  $(1)/usr/lib/lua/luci/lucid/http/handler
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/lucid/handler/villagebus.lua  $(1)/usr/lib/lua/luci/lucid/http/handler
endef

define Package/villagebus-core/postinst
#!/bin/sh
# check if we are on the real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	touch /etc/villagebus-core.postinst.test

	uci add lucid villagebus
  uci set lucid.villagebus="VillagebusPublisher"
  uci set lucid.villagebus.name="Villagebus Publisher"
  uci set lucid.villagebus.home=1

  uci add_list lucid.villagebus.virtual="/villagebus"
  uci add_list lucid.httpd.supports="VillagebusPublisher"
  uci add_list lucid.https.publisher="villagebus"

	uci commit
fi
endef


# - eval packages ----------------------------------------------------------
$(eval $(call BuildPackage,villagebus-core))
