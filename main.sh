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

IPTABLES="iptables"
IFCONFIG="ifconfig"
mainip=""
mainif=""

set -e
set -x

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

do_install()
{
	apt-get install squid
	apt-get install apache2-utils
	apt-get install prips
}

expand_ip()
{
	local ip="$*"
	local nip
	case "$ip" in
		*-*)
			startip=$(echo $ip | awk -F - '{print $1}')
			endip=$(echo $ip | awk -F - '{print $2}')
			for nip in $(prips $startip $endip) ; do
				echo $nip
			done
		;;
		*/*)
			for nip in $(prips $ip) ; do
				echo $nip
			done
		;;
		*)
			echo $ip
		;;
	esac
}

generate_ip_list()
{
	local ips
	local ip
	grep "^AddIP " proxy.conf | while read line; do
		ips=$(echo $line | cut -b 6-)
		for ip in $ips; do
			expand_ip "$ip"
		done
	done
}

add_alias()
{
	local ifc="$1"
	local count=$2
	local ip="$3"
	if [ "$ip" != "$mainip" ]; then
		$IFCONFIG $ifc:$count $ip netmask 255.255.255.255 up
	fi
}

create_chain()
{
	local chain="$1"
	local srcip="$2"
	set +e
	$IPTABLES -t nat -L "$chain" -nv >/dev/null 2>&1
	ret=$?
	set -e
	if [ $ret -ne 0 ]; then
		echo Creating new chain $chain
		$IPTABLES -t nat -N "$chain"
	else
		echo chain $chain already exists
	fi
	if [ -n "$srcip" ]; then
		$IPTABLES -t nat -A MYPROXY -p tcp -s "$srcip" -j $chain
		$IPTABLES -t mangle -I MYPROXY -p tcp -s "$srcip" -j ACCEPT
	else
		$IPTABLES -t nat -A MYPROXY -p tcp -j $chain
		$IPTABLES -t mangle -I MYPROXY -p tcp -j ACCEPT
	fi
}

add_my_ip_to_squid()
{
	local ip=$1
	local ipname
	ipname=myip_$(echo $ip | sed 's/\./_/g')
	echo acl $ipname myip $ip >> /etc/squid/myips.conf
	echo tcp_outgoing_address $ip $ipname >> /etc/squid/myips.conf
}


add_dnat_chain()
{
	local chain="$1"
	local myip="$2"
	local dport="$3"
	$IPTABLES -t nat -A "$chain" -p tcp -d "$myip" --dport "$dport" -j DNAT --to-destination "$myip:3128"
}

add_http_access()
{
	local srcname="$1"
	local myip="$2"
	local ipname
	if [ $srcname = SRC_ANY ]; then
		if [ $myip = any ]; then
			echo "http_access allow all" >> /etc/squid/acls.conf
		else
			ipname=myip_$(echo $myip | sed 's/\./_/g')
			echo "http_access allow $ipname $aclsuffix" >> /etc/squid/acls.conf
		fi
	else
		# src is a particular ip
		if [ $myip = any ]; then
			echo "http_access allow $srcname $aclsuffix" >> /etc/squid/acls.conf
		else
			ipname=myip_$(echo $myip | sed 's/\./_/g')
			echo "http_access allow $srcname $ipname $aclsuffix" >> /etc/squid/acls.conf
		fi
	fi
}

add_acl()
{
	echo "acl $*" >> /etc/squid/acls.conf
}

allow_ports()
{
	local chain="$1"
	local myip="$2"
	local ports="$3"

	case $ports in
		*-*)
			startport=$(echo $ports | awk -F - '{print $1}')
			endport=$(echo $ports | awk -F - '{print $2}')
			for port in $(seq $startport $endport); do
				add_dnat_chain "$chain" "$myip" "$port"
			done
		;;
		*)
			add_dnat_chain "$chain" "$myip" "$ports"
		;;
	esac
}

allow_dests()
{
	local chain="$1"
	local myips="$2"
	local ports="$3"
	local ip_list

	case $myips in
		any)
			add_http_access $chain any
			ip_list=$(generate_ip_list)
			for myip in $ip_list; do
				allow_ports $chain "$myip" "$ports"
			done
		;;
		*)
			myip_list=$(expand_ip $myips)
			for myip in $myip_list; do
				add_http_access $chain "$myip" 
				allow_ports $chain "$myip" "$ports"
			done
		;;
	esac
}

allow_sources()
{
	local myips=$2
	local ports=$3
	local srcip
	case $1 in
		any)
			create_chain SRC_ANY
			allow_dests SRC_ANY "$myips" "$ports"
		;;
		*)
			source_list=$(expand_ip $sources)
			for srcip in $source_list; do
				chain=SRC_$(echo $srcip | sed 's/\./_/g')
				create_chain "$chain" "$srcip"
				add_acl $chain src $srcip
				allow_dests "$chain" "$myips" "$ports"
			done
		;;
	esac
}

add_allow_rules()
{
	grep "^Allow " proxy.conf | while read line; do
		echo $line
		sources=$(echo $line | awk '{print $2}')
		myips=$(echo $line | awk '{print $3}')
		ports=$(echo $line | awk '{print $4}')
		auth=$(echo $line | awk '{print $5}')
		if [ -z "$auth"]; then
			aclsuffix=""
		else
			aclsuffix=authenticated
		fi
		allow_sources $sources $myips $ports
	done
}

add_users()
{
	grep "^AddUser " proxy.conf | while read line; do
		echo $line
		user=$(echo $line | awk '{print $2}')
		pass=$(echo $line | awk '{print $3}')
		htpasswd -b /etc/squid/passwords "$user" "$pass"
	done
}

do_setup()
{
	local count
	local ip_list
	if [ ! -d /etc/squid ]; then
		error_exit "Squid is not installed yet."
	fi

	mainip=$(grep "^MainIP" -i proxy.conf | awk '{print $2}')
	[ -z "$mainip" ] && error_exit "MainIP $mainip not found on any interface"
	mainif=$(ip addr show | grep "$mainip" | awk '{print $7}')
	[ -z "$mainif" ] && error_exit "Could not find network interface on which $mainip is located"
	echo Main interface is $mainif
	cp ./files/squid.conf /etc/squid/squid.conf
	touch /etc/squid/passwords /etc/squid/acls.conf /etc/squid/myips.conf
	truncate --size 0 /etc/squid/myips.conf
	truncate --size 0 /etc/squid/acls.conf
	truncate --size 0 /etc/squid/passwords

	iptables -t nat -F 
	iptables -t nat -X
	iptables -t mangle -F
	iptables -t mangle -X
	iptables -t nat -N MYPROXY
	iptables -t mangle -N MYPROXY
	iptables -t nat -I PREROUTING -j MYPROXY
	iptables -t mangle -A PREROUTING -p tcp --dport 22 -j ACCEPT
	iptables -t mangle -A PREROUTING -j MYPROXY
	sudo iptables -t mangle -A PREROUTING -p tcp -m state --state NEW --dport 3128 -j DROP

	ip_list=$(generate_ip_list)

	count=0
	for ip in $ip_list; do
		add_alias $mainif $count $ip
		add_my_ip_to_squid $ip
		count=$(expr $count + 1)
	done

	add_users

	add_allow_rules

	squid -k reconfigure
	echo Setup done
}

do_reset()
{
	./reset.sh
	rm -f /etc/squid/passwords /etc/squid/acls.conf /etc/squid/myips.conf
	if [ -f /etc/squid/squid.conf ]; then
		cp ./files/squid.conf.org /etc/squid/squid.conf
	fi
	squid -k reconfigure
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
