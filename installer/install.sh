#!/bin/sh
#
# Virtualmin Installation Bootstrapper for FreeBSD
#
# Copyright (c) 2015, Daniel Morante
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -e

# FreeBSD should have fetch installed by default.
export FETCH=$(which fetch)
export TAR=$(which tar)

# Continue to support versions older than 10-RELEASE (for now)
if $(which freebsd-version > /dev/null); then
	export OS_VERSION=$(/bin/freebsd-version | awk -F '-' '{ print $1}')
	export PRE10_RELEASE=false
else
	export OS_VERSION=$(uname -r | cut -d'-' -f1)
	export PRE10_RELEASE=true
fi

export LOG=~/virtualmin-install.log

############################
# Sanity Checks
############################

# Make sure we are on FreeBSD
if [ "$OSTYPE" != "FreeBSD" ]; then
	echo "Fatal Error: This Virtualmin install script is for FreeBSD"
	exit 1
fi

# Currently we support FreeBSD 9.x thru 12.x
if [ $(echo $OS_VERSION | awk -F '.' '{ print $1 }') -lt "9" ]; then
	echo "Fatal Error: This script requires at least FreeBSD version 9.x"
	exit 1
fi

# Only root can run this
if [ $(id -u) -ne 0 ]; then
	echo "Fatal Error: The Virtualmin install script must be run as root"
	exit 1
fi

# Check for localhost in /etc/hosts
grep localhost /etc/hosts >/dev/null
if [ "$?" != 0 ]; then
	echo "There is no localhost entry in /etc/hosts. Installation cannot continue."
	exit 1
fi

# Find system temporary directory
if [ "$TMPDIR" = "" ]; then
	TMPDIR=/tmp
fi

# Check whether TMPDIR is mounted noexec (everything will fail, if so)
if [ ! -z "$(mount | grep ${TMPDIR} | grep noexec)" ]; then
	echo "${TMPDIR} directory is mounted noexec.  Installation cannot continue."
	exit 1
fi

# Support overrides via env variables.
# TODO: Move elsewhere?
[ -z "${LDAP_URI}" ] || [ -z "${LDAP_BASE_DN}" ]
SKIP_LDAP_SERVER_INSTALL=$?

##########################
# Initializtion
##########################

# Temporary directory to store supporting libs
TMPDIR=$TMPDIR/.virtualmin-$$
if [ -e "$TMPDIR" ]; then
	rm -rf $TMPDIR
fi

mkdir -p $TMPDIR/files
srcdir=$TMPDIR/files
cd $srcdir

# Download and extract libraries
$FETCH -o $TMPDIR http://ftp.morante.net/pub/FreeBSD/extra/virtualmin/freebsd-virtualmin.tar.xz
$TAR -xzf $TMPDIR/freebsd-virtualmin.tar.xz -C $srcdir

chmod +x $srcdir/spinner

# Load Libraries
. $srcdir/packages.subr
. $srcdir/util.subr
. $srcdir/system.subr
. $srcdir/install.subr

##########################
# System Setup
##########################

setup_pkg_repos
set +e
init_logging
generate_self_signed_ssl_certificate

##########################
# Begin Install
##########################

logger_info "FreeBSD Operating system version: $OS_VERSION"

setup_hostname
config_discovery_ldap

install_core_services
install_core_utilities

disable_sendmail
disable_sendmail_tasks

setup_apache
setup_postfix
setup_dovecot
setup_mysql
setup_postgresql
setup_openldap

setup_webmin
setup_usermin

webmin_configure_bind
webmin_configure_apache
webmin_configure_dovecot
webmin_configure_mysql
webmin_configure_postgresql
webmin_configure_openldap

install_virtualmin_modules

enable_services

##########################
# Complete
##########################

start_services
resolvconf_local_nameserver_ip

logger_info "Installation is complete.  You may now login to Virtualmin at https://$(hostname -f):10000 (https://$(getent hosts $(hostname -f) | awk '{ print $1 }'):10000)"

##########################
# Clean Up
##########################

if [ -e "$TMPDIR" ]; then
	rm -rf $TMPDIR
fi
