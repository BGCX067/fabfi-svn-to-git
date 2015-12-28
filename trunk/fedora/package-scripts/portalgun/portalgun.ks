# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# - package spec -----------------------------------------------------------
%packages
lua
lua-logging
%end


# - post-install script ----------------------------------------------------
%post
touch /schoolnet.portalgun
%end
