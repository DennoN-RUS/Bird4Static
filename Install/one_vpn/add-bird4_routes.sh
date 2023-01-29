#!/bin/sh

 #USER VARIABLE
DEBUG=0
DISABLE_URLS=0
ISP=ISPINPUT
VPN1=VPN1INPUT
HOMEPATH=HOMEPATHINPUT
SYSTEM_FOLDER=SYSTEMFOLDERINPUT
URLS="URLINPUT"

 #SCRIPT VARIABE
BLACKLIST=$HOMEPATH/lists/antifilter.list
ROUTE_FORCE_ISP=$SYSTEM_FOLDER/etc/bird4-force-isp.list
ROUTE_FORCE_VPN1=$SYSTEM_FOLDER/etc/bird4-force-vpn1.list
ROUTE_BASE_VPN1=$SYSTEM_FOLDER/etc/bird4-base-vpn1.list
VPN1TXT=$HOMEPATH/lists/user-vpn.list
ISPTXT=$HOMEPATH/lists/user-isp.list
MD5_SUM=$HOMEPATH/scripts/sum.md5

source $HOMEPATH/scripts/func.sh

 #WAIT DNS
wait_dns_func

 #INIT FILES
WORK_FILES="$BLACKLIST \
            $ROUTE_FORCE_ISP $ROUTE_FORCE_VPN1 \
            $ROUTE_BASE_VPN1 \
            $MD5_SUM"
init_files_func $WORK_FILES

 #BASE_LIST
curl_funk $URLS $BLACKLIST | diff_funk $BLACKLIST -
ipr_func $VPN1 $BLACKLIST | diff_funk $ROUTE_BASE_VPN1 -

 #FORCE_LIST
ipr_func $ISP $ISPTXT | diff_funk $ROUTE_FORCE_ISP -
ipr_func $VPN1 $VPN1TXT | diff_funk $ROUTE_FORCE_VPN1 -

 #RESTART BIRD
restart_bird_func

 #CHECK DUPLICATE
check_dupl_func
