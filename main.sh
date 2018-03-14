#!/bin/bash

if [ "$EUID" != 0"" ]; then
	echo "Please run as root : sudo $0 $*"
	exit 1
fi

cd `dirname $0`
if [ ! -f "proxy.conf" ]; then
	echo "Could not find proxy.conf in current path"
	exit 1
fi

set -e

usage()
{
	echo "usage: $0 install"
	echo "usage: $0 setup"
	echo "usage: $0 reset"
	exit 1
}

error_exit()
{
	echo ERROR: $*
	exit 1
}

setup_squid()
{
	if [ ! -f /etc/squid1 ]; then
		error_exit "Squid is not installed yet."
	fi
	cp ./files/squid.conf /etc/squid/squid.conf
	touch /etc/squid/passwords /etc/squid/acls.conf /etc/squid/myips.conf
}

do_install()
{
	apt-get install squid
	apt-get install apache2-utils
	apt-get install prips
}

do_setup()
{
	setup_squid
	MainIP=$(grep "^MainIP" proxy.conf | head -n 1 | awk '{print $2}')
	[ -z "$MainIP" ] && error_exit "MainIP $MainIP not found on any interface"
	MainIF=$(ip -o addr | awk '{split($4, a, "/"); print $2" : "a[1]}' | grep $MainIP | awk '{print $1}')
	[ -z "$MainIF" ] && error_exit "Could not find network interface on which $MainIP is located"

	echo Main interface is $MainIF


}

do_reset()
{
	./reset.sh
	rm -f /etc/squid/passwords /etc/squid/acls.conf /etc/squid/myips.conf
	cp ./files/squid.conf.org /etc/squid/squid.conf
}

case "$1" in
	install)
		do_install
	;;
	setup)
		do_setup
	;;
	reset)
		do_reset
	;;
	*)
		usage
	;;
esac
