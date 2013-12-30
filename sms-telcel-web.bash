#!/bin/bash

# Script to send SMS alerts to a Telcel cell phone.
# Useful to alert myself when a server goes down.
#
# Copyright 2013, Octavio Alvarez <alvarezp@alvarezp.com>
# Released under the WTFPLv2. http://www.wtfpl.net/about/

[ $# -lt 2 ] && {
	echo "usage: sms-telcel number message"
	exit 1;
}

PHONE=$1
shift
MESSAGE="$*"

wget -O - -q --post-data='numTelcel='"$PHONE"'&mensaje='"$MESSAGE"'&nomTel=Monitor' --referer='http://www.telcel.com/apps/menes/begin.do' http://www.telcel.com/apps/menes/registraMensajeSencillo.do > /dev/null
