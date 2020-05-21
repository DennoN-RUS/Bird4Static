#!/bin/sh

[ "$1" == "hook" ] || exit
[ "$id" == "L2TP0" ] || exit

case ${change}-${connected}-${link}-${up} in
	link-no-down-down)
		ip rule del table 1000
	/opt/etc/init.d/S04bird1-ipv4 stop
	;;
	link-yes-up-up)
	if [ -z "$(ip rule | grep 1000)" ]; then
	        ip rule add table 1000
	fi
	/opt/etc/init.d/S04bird1-ipv4 start
	;;
esac
