# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# ubuntu deps are: ruby ruby-dev zlib1g-dev rake rubygems libxml2-dev
#                  libxslt1-dev libsqlite3-dev libhttpclient-ruby 
#                  imagemagick irb


# TODO RPM package for canvas-lms
# TODO RPM Package for libhttpclient-ruby or post-install via rubygems?
#      See: http://raa.ruby-lang.org/project/httpclient/2.1.0
#           https://bugzilla.redhat.com/show_bug.cgi?id=179940



# - package spec -----------------------------------------------------------
%packages
gcc-c++  # grf - bluecloth's autoconf is broken and the author doesn't want to admit it
ruby
ruby-devel
ruby-irb
rubygems
rubygem-rake

# sql
libsq3-devel

# libraries
glibc-devel
zlib-devel
libxslt-devel
libxml2-devel
ImageMagick
%end


# - pre-install script ----------------------------------------------------
%pre
touch /schoolnet.canvas-lms.pre
sudo gem install httpclient --no-rdoc --no-ri
sudo gem install bundler --no-rdoc --no-ri
# copy instructure-canvas-lms-* over from dl/
# untar it & cd it
# bundle install --without postgres mysql
%end

# - post-install script ----------------------------------------------------
%post
touch /schoolnet.canvas-lms
%end
