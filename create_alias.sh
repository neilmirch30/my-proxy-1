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
echo "Creating alias on $iface"

count=0
grep "^AddIPRange" proxy.conf | while read x startip endip; do
	for ip in $(prips $startip $endip) ; do
		echo ifconfig $iface:$count $ip/32
		(( count++ )) ; 
	done
done

