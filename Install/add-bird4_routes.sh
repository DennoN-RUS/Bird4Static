#!/bin/sh

ISP=ISPINPUT
VPN=VPNINPUT
URL0=https://antifilter.download/list/allyouneed.lst
#URL0=https://antifilter.download/list/ip.lst

HOMEPATH=/opt/root/Bird4Static

ROUTE=/opt/etc/bird4-routes.list
VPNTXT=$HOMEPATH/lists/user-vpn.list
ISPTXT=$HOMEPATH/lists/user-isp.list

#curl $URL0 | sed 's/^/route /' | sed  's/$/\/32 via "'$VPN'";/' > $ROUTE
curl $URL0 | sed 's/^/route /' | sed  's/$/ via "'$VPN'";/' > $ROUTE
$HOMEPATH/scripts/addip.sh $VPNTXT $VPN $ROUTE
$HOMEPATH/scripts/addip.sh $ISPTXT $ISP $ROUTE

killall -s SIGHUP bird4
