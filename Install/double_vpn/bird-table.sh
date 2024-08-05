#!/bin/sh

PATH=/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin

start(){
	if [ -z "$(ip rule | awk '/^30020/')" ]; then
		ip rule add table 1020 priority 30020
	fi
	if [ -z "$(ip rule | awk '/^30021/')" ]; then
		ip rule add table 1021 priority 30021
	fi
	if [ -z "$(ip rule | awk '/^30022/')" ]; then
		ip rule add table 1022 priority 30022
	fi
}

stop(){
	if [ -n "$(ip rule | awk '/^30020/')" ]; then
		ip rule del table 1020
	fi
	if [ -n "$(ip rule | awk '/^30021/')" ]; then
		ip rule del table 1021
	fi
	if [ -n "$(ip rule | awk '/^30022/')" ]; then
		ip rule del table 1022
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
