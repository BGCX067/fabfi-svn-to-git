# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# - package spec -----------------------------------------------------------
%packages
wordpress
wordpress-plugin-bad-behavior
wordpress-plugin-defaults
%end


# - post-install script ----------------------------------------------------
%post
touch /schoolnet.wordpress
%end
