#!/bin/sh

ISP=eth3
VPN=ppp0
URL0=https://antifilter.download/list/allyouneed.lst

ROUTE=/opt/etc/bird4-routes.list
VPNTXT=/opt/etc/bird4-vpn.txt
ISPTXT=/opt/etc/bird4-isp.txt

curl $URL0 | sed 's/^/route /' | sed  's/$/ via "'$VPN'";/' > $ROUTE
/opt/root/addip.sh $VPNTXT $VPN $ROUTE
/opt/root/addip.sh $ISPTXT $ISP $ROUTE

killall -s SIGHUP bird4
