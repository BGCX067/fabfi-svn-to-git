# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# - package spec -----------------------------------------------------------
%packages
%end


# - pre-install script ----------------------------------------------------
%pre
touch /schoolnet.network.pre
%end


# - post-install script ----------------------------------------------------
%post
touch /schoolnet.network
# TODO files/interfaces
# TODO files/make_transparent
# TODO files/resolv.conf
%end
