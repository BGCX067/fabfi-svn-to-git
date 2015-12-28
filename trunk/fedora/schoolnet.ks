# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# - includes ---------------------------------------------------------------
%include include/base.ks
%include include/minimization.ks

# - subsystems -------------------------------------------------------------
%include package-scripts/squid/squid.ks
%include package-scripts/aaa/aaa.ks
%include package-scripts/wordpress/wordpress.ks
%include package-scripts/canvas-lms/canvas-lms.ks
%include package-scripts/reddit/reddit.ks


# - build configuration ----------------------------------------------------
part / --size 4096


# - system configuration ---------------------------------------------------
#lang C
#keyboard us
#timezone US/Eastern
#auth --useshadow --enablemd5
#selinux --permissive
#firewall --disabled
#bootloader --timeout=1 --append="acpi=force"
#network --bootproto=dhcp --device=eth0 --onboot=on
#services --enabled=network
#rootpw --iscrypted $1$uw6MV$m6VtUWPed4SqgoW6fKfTZ/


# - package spec -----------------------------------------------------------
%packages
# must-haves
nano
emacs-nox
%end


# - post-install script ----------------------------------------------------
%post
touch /schoolnet
%end
