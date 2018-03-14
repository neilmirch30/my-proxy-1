#!/bin/bash

cd `dirname $0`

if [ ! -f proxy.conf ]; then
	echo "$0: proxy.conf not found"
	exit 1
fi

mainip=$(grep "^MainIP" -i proxy.conf | awk '{print $2}')
if [ -z "$mainip" ]; then
	echo "$0: MainIP not found in proxy.conf"
	exit 1
fi
iface=$(ip addr show | grep "$mainip" | awk '{print $7}')
if [ -z "$iface" ]; then
	echo "$0: MainIP not found on any interface"
	exit 1
fi

aliases=$(ip addr show | grep "global $iface:" | awk '{print $7}')

do_run()
{
	echo $*
	$*
}

echo Reset started

for alias in $aliases; do
	do_run ifconfig $alias down
done

iptables -t nat -L -nv | grep -q MYPROXY
if [ $? -eq 0 ]; then
	iptables -t nat -D PREROUTING -j MYPROXY
	iptables -t nat -F MYPROXY
	iptables -t nat -X MYPROXY
fi
echo Reset Done
