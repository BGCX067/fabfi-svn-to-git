
# configuration
DEFINITION=schoolnet.ks

livecd :
	-[ -e /var/cache/live ] || { cp -a cache /var/cache/live; }
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
