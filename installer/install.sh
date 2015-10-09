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

# FreeBSD should have fetch installed by default.
export FETCH=$(which fetch)
export TAR=$(which tar)
export OS_VERSION=$(uname -r | cut -d'-' -f1)
export LOG=~/virtualmin-install.log

############################
# Sanity Checks
############################

# Make sure we are on FreeBSD
if [ "$OSTYPE" != "FreeBSD" ]; then
	echo "Fatal Error: This Virtualmin install script is for FreeBSD"
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
. $srcdir/util.subr
. $srcdir/system.subr
. $srcdir/install.subr

##########################
# Setup
##########################

setup_pkg_repos

# Setup log4sh so we can start keeping a proper log while also feeding output
# to the console.
echo "Loading log4sh logging library..."
if pkg install -y log4sh
then 
	# source log4sh (disabling properties file warning)
	LOG4SH_CONFIGURATION="none" . $LOCAL_BASE/lib/log4sh
else
	echo " Could not load logging library from software.virtualmin.com.  Cannot continue."
	echo " We're not just stopping because we don't have a logging library--this probably"
	echo " indicates a serious problem that will prevent successful installation anyway."
	echo " Check network connectivity, name resolution and disk space and try again."
	exit 1
fi

# Setup log4sh properties
# Console output
logger_setLevel INFO
# Debug log
logger_addAppender virtualmin
appender_setAppenderType virtualmin FileAppender
appender_setAppenderFile virtualmin $LOG
appender_setLevel virtualmin ALL
appender_setLayout virtualmin PatternLayout
appender_setPattern virtualmin '%p - %d - %m%n'

logger_info "Started installation log in $LOG"

# Print out some details that we gather before logging existed
logger_debug "Install mode: $mode"
logger_debug "Product: Virtualmin $PRODUCT"
logger_debug "Virtualmin Meta-Package list: $virtualminmeta"
logger_debug "install.sh version: $VER"

##########################
# Begin Install
##########################

logger_info "FreeBSD Operating system version: $OS_VERSION"

install_core_services
install_core_utilities

disable_sendmail
disable_sendmail_tasks

setup_apache
setup_postfix
setup_webmin
setup_usermin

webmin_configure_bind
webmin_configure_apache

install_virtualmin_modules

enable_services
