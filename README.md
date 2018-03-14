Proxy Script Linux Multiple IPs 1 server

Installation Steps

Steps to setup a fresh server
	ssh root@<server-ip->
	git clone https://github.com/voidstarer/my-proxy.git
	cd my-proxy
	Edit the proxy.conf as per your requirement. Refer the proxy.conf for more information.
	sudo ./main.sh install
	sudo ./main.sh setup

Steps to change some configuration on existing server
	ssh root@<server-ip->
	cd my-proxy
	Edit the proxy.conf as per your requirement. Refer the proxy.conf for more information.
	sudo ./main.sh setup

Steps to reset the server to its original state.
	ssh root@<server-ip->
	cd my-proxy
	sudo ./main.sh reset

 ======================================= proxy.conf ====================================

# Sample proxy.conf file
# - This File is case sensitive
# - Any line starting with # is a comment
# - Please note that SPACE character is considered as a separator and not TAB.
# - Please do not add any space at the start of the command.

# MainIP: Specifies the MainIP of the server. As of now, it is assumed that each server can have
# only one MainIP. The main ip-address “SHOULD” be bound to one of the physical interfaces
#  (eth0, etc) of the server, otherwise the script with throw an error and return.
# Syntax:
# MainIP <ip-address>
# Example:
# MainIP 216.246.109.42
MainIP 216.246.109.42

# AddIP : This is used to specify additional IPs of the proxy server. These ip-addresses are
# added as alias/secondary ip-addresses to the MainIP interface. The only exception is MainIP.
# So, if you include MainIP in the AddIP range, it will just be treated like a normal IP with the
# exception that it will not be added as an alias, and therefore does not disturb the main
# interface.
# Syntax:
# For specifying a range of additional ip-addresses:
# AddIP <start-ip-address>-<end-ip-address>
# Example:
# AddIP 1.1.1.1-1.1.1.10
#
# For specifying individual additional ip-addresses
# AddIP <ip-address1> [ <ip-address2> ... ]
# Example:
# AddIP 1.1.1.5 2.2.2.10 3.3.3.15
# 
# You may also combine individual ip-addresses with a range of ip-addresses:
# AddIP <ip-address1> [ <start-ip-address>-<end-ip-address> ... ]
# Example:
# AddIP 216.246.109.43 216.246.109.44-216.246.109.45
# or
# AddIP 216.246.109.43

AddIP 216.246.109.43-216.246.109.46
AddIP 66.225.232.66-66.225.232.94

# Allow: This command can be used to allow the access of proxy. A special
# tag called “any” can be used to indicate “Access for ALL”. This command can be
# specified multiple time. In case of multiple Allow commands, they are executed
# in the order in which they are specified.
# Syntax:
# Allow <client-ip-range> <proxy-ip-range> <port-range> [AUTH]
# Examples:
# E.g. 1) To allow any client to access any proxy-ip on port 2000
# Allow any any 2000
# 
# E.g. 2) To allow any client to access any proxy-ip on port 2000 but only after username 
# and password authentication
# Allow any any 2000 AUTH
#
# E.g. 3) To allow any client to access proxy-ip 66.225.232.66 on port 2000
# Allow any 66.225.232.66 2000
#
#
# E.g. 4) To allow any client to access proxy-ip 66.225.232.66 on port 2000 but only 
# after username and password authentication
# Allow any 66.225.232.66 2000 AUTH
#
# E.g. 5) To allow client 1.1.1.1 to access any proxy-ip on port 2000 
# Allow 1.1.1.1 any 2000
#
# E.g. 6) To allow client 1.1.1.1 to access any proxy-ip on port 2000 but only 
# after username and password authentication
# Allow 1.1.1.1 any 2000 AUTH
#
# E.g. 7) To allow client 1.1.1.1 to access specific proxy-ip on port 2000. If AUTH is suffixed,
# it will enforce username-password authentication. The square braces of AUTH indicate
# that it is optional.
# Allow 1.1.1.1 66.225.232.66 2000 [ AUTH ]
#
# E.g. 8) To allow client 1.1.1.1 to access a range of proxy-ip on port 2000.
#  Allow 1.1.1.1 66.225.232.66-66.225.232.94 2000 [ AUTH ]
# 
# E.g. 9) To allow client 1.1.1.1 to access a range of proxy-ip on and a range of port 2000-2050
#  Allow 1.1.1.1 66.225.232.66-66.225.232.94 2000-2050 [ AUTH ]
#
#
Allow any 216.246.109.42-216.246.109.46 65001-65050
Allow any 66.225.232.66-66.225.232.94 65001-65050

# To add users, please use the below tag
# AddUser <username> <password>
#
AddUser user1 user110
AddUser user2 user210

 ======================================= proxy.conf ====================================
