# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# - package spec -----------------------------------------------------------
%packages
squid
calamaris
%end


# - post-install script ----------------------------------------------------
%post
touch /schoolnet.squid
# TODO copy squid.conf over to /etc/squid
%end


# - post-install nochroot --------------------------------------------------
%post --nochroot
# LIVE_ROOT is the CD's root filesystem
# INSTALL_ROOT is the OS root fileystem
PACKAGE_ROOT=package-scripts/squid

touch $LIVE_ROOT/schoolnet.squid.liveroot
touch $INSTALL_ROOT/schoolnet.squid.installroot
cp $PACKAGE_ROOT/files/squid.conf $INSTALL_ROOT/etc/squid/squid.conf
cp $PACKAGE_ROOT/files/squid.conf $INSTALL_ROOT/etc/squid/squid.conf.schoolnet
%end
