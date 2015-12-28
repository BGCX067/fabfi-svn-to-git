#
# Copyright (C) 2008-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

define imgname
$(BIN_DIR)/$(IMG_PREFIX)-$(2)-$(patsubst jffs2-%,jffs2,$(patsubst squashfs-%,squashfs,$(1)))
endef

VMLINUX:=$(BIN_DIR)/$(IMG_PREFIX)-vmlinux
UIMAGE:=$(BIN_DIR)/$(IMG_PREFIX)-uImage
fs_squash:=squashfs-only
fs_all:=all
fs_4k:=4k
fs_64k:=64k
fs_128k:=128k
ifeq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),y)
	fs_squash:=initramfs
	fs_all:=initramfs
	fs_4k:=initramfs
	fs_64k:=initramfs
	fs_128k:=initramfs
	VMLINUX:=$(BIN_DIR)/$(IMG_PREFIX)-vmlinux-initramfs
	UIMAGE:=$(BIN_DIR)/$(IMG_PREFIX)-uImage-initramfs
endif

define CompressLzma
  $(STAGING_DIR_HOST)/bin/lzma e $(1) -lc1 -lp2 -pb2 $(2)
endef

define PatchKernelLzma
	cp $(KDIR)/vmlinux $(KDIR)/vmlinux-$(1)
	$(STAGING_DIR_HOST)/bin/patch-cmdline $(KDIR)/vmlinux-$(1) '$(strip $(2))'
	$(call CompressLzma,$(KDIR)/vmlinux-$(1),$(KDIR)/vmlinux-$(1).bin.lzma)
endef

define PatchKernelGzip
	cp $(KDIR)/vmlinux $(KDIR)/vmlinux-$(1)
	$(STAGING_DIR_HOST)/bin/patch-cmdline $(KDIR)/vmlinux-$(1) '$(strip $(2))'
	gzip -9 -c $(KDIR)/vmlinux-$(1) > $(KDIR)/vmlinux-$(1).bin.gz
endef

define MkImageLzma
	mkimage -A mips -O linux -T kernel -a 0x80060000 -C lzma \
		-e 0x80060000 -n 'MIPS OpenWrt Linux-$(LINUX_VERSION)' \
		-d $(1) $(2)
endef

define MkImageGzip
	mkimage -A mips -O linux -T kernel -a 0x80060000 -C gzip \
		-e 0x80060000 -n 'MIPS OpenWrt Linux-$(LINUX_VERSION)' \
		-d $(1) $(2)
endef

define Image/BuildKernel
	cp $(KDIR)/vmlinux.elf $(VMLINUX).elf
	cp $(KDIR)/vmlinux $(VMLINUX).bin
	gzip -9 -c $(KDIR)/vmlinux > $(KDIR)/vmlinux.bin.gz
	$(call CompressLzma,$(KDIR)/vmlinux,$(KDIR)/vmlinux.bin.lzma)
	dd if=$(KDIR)/vmlinux.bin.lzma of=$(VMLINUX).lzma bs=65536 conv=sync
	dd if=$(KDIR)/vmlinux.bin.gz of=$(VMLINUX).gz bs=65536 conv=sync
	$(call MkImageGzip,$(KDIR)/vmlinux.bin.gz,$(UIMAGE)-gzip.bin)
	$(call MkImageLzma,$(KDIR)/vmlinux.bin.lzma,$(UIMAGE)-lzma.bin)
	$(call Image/Build/Initramfs)
endef


ubntxm_mtdlayout=mtdparts=spi0.0:256k(u-boot)ro,64k(u-boot-env)ro,1024k(kernel),6528k(rootfs),256k(cfg)ro,64k(EEPROM)ro,7552k@0x50000(firmware)
define Image/Build/UBNTXM
	$(call PatchKernelLzma,$(2),$(3) $(ubntxm_mtdlayout))
	$(call MkImageLzma,$(KDIR)/vmlinux-$(2).bin.lzma,$(KDIR)/vmlinux-$(2).uImage.bin)
	dd if=$(KDIR)/vmlinux-$(2).uImage.bin of=$(KDIR)/vmlinux-$(2).uImage bs=1024k conv=sync
	-$(STAGING_DIR_HOST)/bin/mkfwimage \
		-B $(4) -v $(5).$(6).OpenWrt.$(REVISION) \
		-k $(KDIR)/vmlinux-$(2).uImage \
		-r $(BIN_DIR)/$(IMG_PREFIX)-root.$(1) \
		-o $(call imgname,$(1),$(2))-factory.bin
	( \
		dd if=$(KDIR)/vmlinux-$(2).uImage; \
		dd if=$(BIN_DIR)/$(IMG_PREFIX)-root.$(1); \
	) > $(call imgname,$(1),$(2))-sysupgrade.bin
endef

define Image/Build/UBNT
	$(call PatchKernelLzma,$(2),$(3))
	dd if=$(KDIR)/vmlinux-$(2).bin.lzma of=$(KDIR)/vmlinux-$(2).lzma bs=64k conv=sync
	-$(STAGING_DIR_HOST)/bin/mkfwimage \
		-B $(4) -v $(5).$(6).OpenWrt.$(REVISION) \
		-k $(KDIR)/vmlinux-$(2).lzma \
		-r $(BIN_DIR)/$(IMG_PREFIX)-root.$(1) \
		-o $(call imgname,$(1),$(2))-factory.bin
	-sh $(TOPDIR)/scripts/combined-image.sh \
		"$(KDIR)/vmlinux-$(2).lzma" \
		"$(BIN_DIR)/$(IMG_PREFIX)-root.$(1)" \
		$(call imgname,$(1),$(2))-sysupgrade.bin
endef


define Image/Build/Template/initramfs/initramfs
	$(call Image/Build/$(1)/initramfs,initramfs,$(2),$(3),$(4),$(5),$(6),$(7))
endef

define Image/Build/Template/all/squashfs
	$(call Image/Build/$(1),squashfs,$(2),$(3),$(4),$(5),$(6),$(7))
endef

define Image/Build/Template/all/jffs2-64k
	$(call Image/Build/$(1),jffs2-64k,$(2),$(3),$(4),$(5),$(6),$(7))
endef

define Image/Build/Template/all/jffs2-128k
	$(call Image/Build/$(1),jffs2-128k,$(2),$(3),$(4),$(5),$(6),$(7))
endef

define Image/Build/Template/squashfs-only/squashfs
	$(call Image/Build/$(1),squashfs,$(2),$(3),$(4),$(5),$(6),$(7))
endef

define Image/Build/Template/4k/squashfs
	$(call Image/Build/$(1),squashfs-4k,$(2),$(3),$(4),$(5),$(6),$(7))
endef

define Image/Build/Template/64k/squashfs
	$(call Image/Build/$(1),squashfs,$(2),$(3),$(4),$(5),$(6),$(7))
endef

define Image/Build/Template/64k/jffs2-64k
	$(call Image/Build/$(1),jffs2-64k,$(2),$(3),$(4),$(5),$(6),$(7))
endef

define Image/Build/Template/128k/squashfs
	$(call Image/Build/$(1),squashfs,$(2),$(3),$(4),$(5),$(6),$(7))
endef

define Image/Build/Template/128k/jffs2-128k
	$(call Image/Build/$(1),jffs2-128k,$(2),$(3),$(4),$(5),$(6),$(7))
endef


define Image/Build/Profile/UBNTNANOM
	$(call Image/Build/Template/$(fs_64k)/$(1),UBNTXM,ubnt-nano-m,board=UBNT-NM,XM,UBNTXM,ar7240)
endef

define Image/Build/Profile/UBNT
	$(call Image/Build/Profile/UBNTNANOM,$(1))
endef


define Image/Build/Profile/Default
	$(call Image/Build/Profile/UBNT,$(1))
endef

define Image/Build/squashfs
	$(call prepare_generic_squashfs,$(KDIR)/root.squashfs)
	dd if=$(KDIR)/root.squashfs of=$(KDIR)/root.squashfs-4k.tmp0 bs=4k conv=sync
	$(call add_jffs2_mark,$(KDIR)/root.squashfs-4k.tmp0)
	dd if=$(KDIR)/root.squashfs-4k.tmp0 of=$(BIN_DIR)/$(IMG_PREFIX)-root.squashfs-4k bs=4k conv=sync
	$(call add_jffs2_mark,$(BIN_DIR)/$(IMG_PREFIX)-root.squashfs-4k)
	rm -f $(KDIR)/root.squashfs-4k.tmp0
endef

define Image/Build/Initramfs
	$(call Image/Build/Profile/$(PROFILE),initramfs)
endef

define Image/Build
	$(call Image/Build/$(1))
	dd if=$(KDIR)/root.$(1) of=$(BIN_DIR)/$(IMG_PREFIX)-root.$(1) bs=128k conv=sync

	$(call Image/Build/Profile/$(PROFILE),$(1))
endef

$(eval $(call BuildImage))
