# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# read: https://github.com/Pita/etherpad-lite

# - package spec -----------------------------------------------------------
%packages
openssl
openssl-devel
%end


# - post-install script ----------------------------------------------------
%post.off

# node.js
mkdir /usr/local/src
cd /usr/local/src
wget http://nodejs.org/dist/node-v0.4.11.tar.gz
tar xzvf node-v0.4.11.tar.gz
cd node-v0.4.11
./configure && make && make install

# npm - TODO install from git?
curl http://npmjs.org/install.sh | sh

# etherpad-lite
git clone 'git://github.com/Pita/etherpad-lite.git'
bin/installDeps.sh
bin/run.sh

touch /schoolnet.etherpad-lite
%end
