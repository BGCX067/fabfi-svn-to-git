# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# - package spec -----------------------------------------------------------
%packages

# First, no office
-libreoffice-*
-planner

# Temporary list of things removed from comps but not synced yet
-specspo

# Drop the Java plugin
-icedtea-web
-java-1.6.0-openjdk

# Drop things that pull in perl
-linux-atm
-perf

# No printing
-foomatic-db-ppds
-foomatic

# Dictionaries are big
-aspell-*
-hunspell-*
-man-pages*
-words

# Help and art can be big, too
-gnome-user-docs
-evolution-help
-gnome-games-help
-desktop-backgrounds-basic
-*backgrounds-extras

# Legacy cmdline things we don't want
-nss_db
-krb5-auth-dialog
-krb5-workstation
-pam_krb5
-quota
-nano
-minicom
-dos2unix
-finger
-ftp
-jwhois
-mtr
-pinfo
-rsh
-telnet
-nfs-utils
-ypbind
-yp-tools
-rpcbind
-acpid
-ntsysv

# Drop some system-config things
-system-config-boot
-system-config-language
-system-config-network
-system-config-rootpassword
-system-config-services
-policycoreutils-gui

# More stuff we don't need
-@sound-and-video
-@office
-gnome-speech
-festival
-festival-lib
-cdrdao
-gnome-video-effects
-gnome-games
-transmission-common
-transmission-gtk
-cheese
-cheese-libs
-totem
-evolution-data-server
-evolution-NetworkManager
-evolution
-brasero-nautilus
-brasero-libs
-brasero


%end


# - post-install script ----------------------------------------------------
%post
touch /schoolnet.minimization
%end
