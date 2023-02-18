#!/bin/sh

PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

start(){
	if [ -z "$(ip rule | awk '/^30000/')" ]; then
		ip rule add table force priority 30000
	fi
	if [ -z "$(ip rule | awk '/^30001/')" ]; then
		ip rule add table vpn1 priority 30001
	fi
	if [ -z "$(ip rule | awk '/^30002/')" ]; then
		ip rule add table vpn2 priority 30002
	fi
}

stop(){
	if [ -n "$(ip rule | awk '/^30000/')" ]; then
		ip rule del table force
	fi
	if [ -n "$(ip rule | awk '/^30001/')" ]; then
		ip rule del table vpn1
	fi
	if [ -n "$(ip rule | awk '/^30002/')" ]; then
		ip rule del table vpn2
	fi
}

case "$1" in
	start)
	start
	;;

	stop | kill)
	stop
	;;

	restart)
	stop
	sleep 5
	start
	;;
	*)
	echo "Usage: $0 {start|stop|kill|restart}"
	;;
esac 
