#!/bin/sh

 #USER VARIABLE
DEBUG=0
ISP=ISPINPUT
VPN1=VPN1INPUT
VPN2=VPN2INPUT
HOMEPATH=HOMEPATHINPUT
SYSTEM_FOLDER=SYSTEMFOLDERINPUT
URL0=URLINPUT

 #SCRIPT VARIABE
BLACKLIST=$HOMEPATH/lists/antifilter.list
ROUTE_FORCE_ISP=$SYSTEM_FOLDER/etc/bird4-force-isp.list
ROUTE_FORCE_VPN1=$SYSTEM_FOLDER/etc/bird4-force-vpn1.list
ROUTE_FORCE_VPN2=$SYSTEM_FOLDER/etc/bird4-force-vpn2.list
ROUTE_BASE_VPN1=$SYSTEM_FOLDER/etc/bird4-base-vpn1.list
ROUTE_USER_VPN1=$SYSTEM_FOLDER/etc/bird4-user-vpn1.list
ROUTE_BASE_VPN2=$SYSTEM_FOLDER/etc/bird4-base-vpn2.list
ROUTE_USER_VPN2=$SYSTEM_FOLDER/etc/bird4-user-vpn2.list
VPNTXT=$HOMEPATH/lists/user-vpn.list
VPN1TXT=$HOMEPATH/lists/user-vpn1.list
VPN2TXT=$HOMEPATH/lists/user-vpn2.list
ISPTXT=$HOMEPATH/lists/user-isp.list
MD5_SUM=$HOMEPATH/scripts/sum.md5

source $HOMEPATH/scripts/func.sh

 #WAIT DNS
wait_dns_func

 #INIT FILES
WORK_FILES="$BLACKLIST \
            $ROUTE_FORCE_ISP $ROUTE_FORCE_VPN1 $ROUTE_FORCE_VPN2 \
            $ROUTE_BASE_VPN1 $ROUTE_USER_VPN1 \
            $ROUTE_BASE_VPN2 $ROUTE_USER_VPN2 \
            $MD5_SUM"
init_files_func $WORK_FILES

 #BASE_LIST
curl -s $URL0 | sort | diff_funk $BLACKLIST - check
ipr_func $VPN1 $BLACKLIST | diff_funk $ROUTE_BASE_VPN1 -
sed "s/$VPN1/$VPN2/g" $ROUTE_BASE_VPN1 | diff_funk $ROUTE_BASE_VPN2 -

 #BASE_USER_LIST
ipr_func $VPN1 $VPNTXT | diff_funk $ROUTE_USER_VPN1 -
sed "s/$VPN1/$VPN2/g" $ROUTE_USER_VPN1 | diff_funk $ROUTE_USER_VPN2 -

 #FORCE_LIST
ipr_func $ISP $ISPTXT | diff_funk $ROUTE_FORCE_ISP -
ipr_func $VPN1 $VPN1TXT | diff_funk $ROUTE_FORCE_VPN1 -
ipr_func $VPN2 $VPN2TXT | diff_funk $ROUTE_FORCE_VPN2 -

 #RESTART BIRD
restart_bird_func

 #CHECK DUPLICATE
check_dupl_func
