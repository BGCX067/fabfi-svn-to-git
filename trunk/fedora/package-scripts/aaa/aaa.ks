# SchoolNet LiveCD Distribution
#
# Copyright (C) 2011 SchoolNet
# All rights reserved.
# 
# This software is licensed as free software under the terms of the
# New BSD License. See /LICENSE for more information. 


# - package spec -----------------------------------------------------------
%packages
# freeradius
freeradius
freeradius-utils
freeradius-ldap
freeradius-krb5
freeradius-python

# openldap
openldap
openldap-clients
openldap-servers
openldap-servers-sql

# kerberos
krb5-appl-clients
krb5-appl-servers
krb5-workstation
krb5-server
krb5-server-ldap

# misc
echoping-ldap
openssh-ldap
#libobjc # needed for openvpn-auth-ldap
#openvpn-auth-ldap
pam_ldap
pam_krb5
python-ldap
python-kerberos
python-krbV
%end


# - post-install script ----------------------------------------------------
%post
touch /schoolnet.aaa
%end
