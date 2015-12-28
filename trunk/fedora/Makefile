# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# - configuration ----------------------------------------------------------
DEFINITION=schoolnet.ks


# - targets ----------------------------------------------------------------
livecd :
	-[ -e /var/cache/live ] || { cp -a cache /var/cache/live; }
	sudo setenforce 0
	sudo livecd-creator -v \
      --config=$(DEFINITION) \
      --cache=/var/cache/live
	-[ -e ./cache.prev ] && { rm -rf cache.prev;   }
	-[ -e cache ]        && { mv cache cache.prev; }
	-cp -a /var/cache/live cache

clean : 
	rm -rf *.iso fedora updates 

distclean: clean
	rm -rf cache cache.prev 
