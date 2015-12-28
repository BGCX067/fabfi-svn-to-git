
include $(TOPDIR)/rules.mk

# - configuration ----------------------------------------------------------
PKG_NAME:=fabfi-core
PKG_VERSION:=0.2
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/fabfi-core
	SECTION:=base
	CATEGORY:=Fabfi
	TITLE:= fabfi mesh network configuration scripts
	DEPENDS:=+olsrd +olsrd-mod-dyn-gw +olsrd-mod-nameservice +radvd +aiccu +ntpdate
	VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)
	URL:=http://fabfi.org
endef

define Package/fabfi-core/description
	A collection of helper scripts and files necessary for setting up fabfi wireless mesh network
endef

define Build/Compile
	# to be done 
endef

define Package/fabfi-core/install
	$(INSTALL_DIR) $(1)/usr/bin/fabfi/
	$(INSTALL_DIR) $(1)/usr/share/fabfi/
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface/
	$(INSTALL_DATA) ./files/* $(1)/usr/share/fabfi/
	$(INSTALL_BIN) ./scripts/run_once $(1)/etc/init.d/
	$(INSTALL_BIN) ./scripts/* $(1)/usr/bin/fabfi/
	
	$(LN) /usr/bin/fabfi/setup.sh $(1)/setup
	#$(LN) /usr/bin/fabfi/initial_setup $(1)/etc/uci-defaults/Zrun_once
endef

define Package/fabfi-core/postinst
#!/bin/sh
# check if we are on the real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/run_once enable
#	/etc/init.d/siit-init enable
	uci commit	
fi
endef


# - eval packages ----------------------------------------------------------
$(eval $(call BuildPackage,fabfi-core))

