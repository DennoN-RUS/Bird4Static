#!/bin/sh

[ "$1" != "hook" ] && exit 0
[ "$id" != "L2TP0" ] && exit 0

case ${change}-${connected}-${link}-${up} in
	link-no-down-down)
	/opt/etc/init.d/S04bird1-ipv4 stop
	;;
	link-yes-up-up)
	if [ -z "$(ip rule | awk '/^2150/' )" ]; then
		ip rule add table 1000 priority 2150
	fi
	/opt/etc/cron.daily/add-bird4_routes.sh
	/opt/etc/init.d/S04bird1-ipv4 start
	;;
esac
