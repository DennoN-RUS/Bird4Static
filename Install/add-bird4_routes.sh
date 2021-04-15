#!/bin/sh

ISP=ISPINPUT
VPN=VPNINPUT
URL0=https://antifilter.download/list/allyouneed.lst
#URL0=https://antifilter.download/list/ip.lst

ROUTE=/opt/etc/bird4-routes.list
VPNTXT=$HOME/Bird4Static/lists/user-vpn.list
ISPTXT=$HOME/Bird4Static/lists/user-isp.list

#curl $URL0 | sed 's/^/route /' | sed  's/$/\/32 via "'$VPN'";/' > $ROUTE
curl $URL0 | sed 's/^/route /' | sed  's/$/ via "'$VPN'";/' > $ROUTE
$HOME/Bird4Static/scripts/addip.sh $VPNTXT $VPN $ROUTE
$HOME/Bird4Static/scripts/addip.sh $ISPTXT $ISP $ROUTE

killall -s SIGHUP bird4
