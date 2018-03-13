#!/bin/bash

if [ "$EUID" -ne 0 ]; then
	echo "Please run as root : sudo $0 $*"
	exit 1
fi

cd `dirname $0`
if [ ! -f "proxy.conf" ]; then
	echo "Could not find proxy.conf in current path"
	exit 1
fi

usage()
{
	echo "usage: $0 install"
	exit 1
}

error_exit()
{
	echo $*
	exit 1
}

do_install()
{
	MainIP=$(grep "^MainIP" proxy.conf | head -n 1 | awk '{print $2}')
	[ -z "$MainIP" ] && error_exit "MainIP $MainIP not found on interface"
	MainIF=$(ip -o addr | awk '{split($4, a, "/"); print $2" : "a[1]}' | grep $MainIP | awk '{print $1}')
	[ -z "$MainIF" ] && error_exit "Could not find network interface on which $MainIP is located"
	
	echo Main interface is $MainIF

	apt-get install squid
}

case "$1" in
	install)
		do_install
	;;
	addip)
		echo addip called
	;;
	*)
	;;
esac
