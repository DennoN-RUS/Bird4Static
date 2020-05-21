#!/bin/sh

ISP=eth3
VPN=ppp0
URL0=https://antifilter.download/list/allyouneed.lst
ROUTE=/opt/etc/bird4-routes.list
VPNTXT=/opt/etc/bird4-vpn.txt
VPNLST=/opt/etc/bird4-vpn.list
ISPTXT=/opt/etc/bird4-isp.txt
ISPLST=/opt/etc/bird4-isp.list

curl $URL0 | sed 's/^/route /' | sed  's/$/ via "'$VPN'";/' > $ROUTE
/opt/root/addip.sh $VPNTXT $VPN $VPNLST
/opt/root/addip.sh $ISPTXT $ISP $ISPLST

killall -s SIGHUP bird4
