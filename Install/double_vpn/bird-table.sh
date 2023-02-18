#!/bin/sh

PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

start(){
	if [ -z "$(ip rule | awk '/^30000/')" ]; then
		ip rule add table 1000 priority 30000
	fi
	if [ -z "$(ip rule | awk '/^30001/')" ]; then
		ip rule add table 1001 priority 30001
	fi
	if [ -z "$(ip rule | awk '/^30002/')" ]; then
		ip rule add table 1002 priority 30002
	fi
}

stop(){
	if [ -n "$(ip rule | awk '/^30000/')" ]; then
		ip rule del table 1000
	fi
	if [ -n "$(ip rule | awk '/^30001/')" ]; then
		ip rule del table 1001
	fi
	if [ -n "$(ip rule | awk '/^30002/')" ]; then
		ip rule del table 1002
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
