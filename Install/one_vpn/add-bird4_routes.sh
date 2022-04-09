#!/bin/sh

 #USER VARIABLE
ISP=ISPINPUT
VPN1=VPN1INPUT
HOMEPATH=/opt/root/Bird4Static
URL0=https://antifilter.download/list/allyouneed.lst

 #SCRIPT VARIABE
BLACKLIST=$HOMEPATH/lists/antifilter.list
ROUTE_FORCE_ISP=/opt/etc/bird4-force-isp.list
ROUTE_FORCE_VPN1=/opt/etc/bird4-force-vpn1.list
ROUTE_BASE_VPN1=/opt/etc/bird4-base-vpn1.list
VPN1TXT=$HOMEPATH/lists/user-vpn.list
ISPTXT=$HOMEPATH/lists/user-isp.list
MD5_SUM=$HOMEPATH/scripts/sum.md5

 #IPRANGE FUNCTION
ipr_func() {
  if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    iprange --print-prefix "route " --print-suffix-nets " via $1;" --print-suffix-ips "/32 via $1;" "$2"
  else
    iprange --print-prefix "route " --print-suffix-nets " via \"$1\";" --print-suffix-ips "/32 via \"$1\";" "$2"
  fi
}

 #INIT FILES
WORK_FILES="$BLACKLIST \
            $ROUTE_FORCE_ISP $ROUTE_FORCE_VPN1 \
            $ROUTE_BASE_VPN1 \
            $MD5_SUM"
touch $WORK_FILES
for var in $WORK_FILES; do
  [ -s $var ] || echo 1 > $var
done

 #WAIT DNS
until ADDRS=$(dig +short google.com @localhost -p 53) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done

 #BASE_LIST
curl -sk $URL0 | sort | diff -u $BLACKLIST - | patch $BLACKLIST -
ipr_func $VPN1 $BLACKLIST | diff -u $ROUTE_BASE_VPN1 - | patch $ROUTE_BASE_VPN1 -

 #FORCE_LIST
ipr_func $ISP $ISPTXT | diff -u $ROUTE_FORCE_ISP - | patch $ROUTE_FORCE_ISP -
ipr_func $VPN1 $VPN1TXT | diff -u $ROUTE_FORCE_VPN1 - | patch $ROUTE_FORCE_VPN1 -

 #RESTART BIRD
if [ "$(cat $MD5_SUM)" != "$(md5sum /opt/etc/bird4*)" ]; then
  md5sum /opt/etc/bird4* > $MD5_SUM
  echo "Restarting bird"
  killall -s SIGHUP bird4
fi
