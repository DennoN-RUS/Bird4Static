#!/bin/sh

 #USER VARIABLE
ISP=ISPINPUT
VPN1=VPN1INPUT
URLS="URLINPUT"

 #SCRIPT VARIABE
HOMEPATH=HOMEFOLDERINPUT

source $HOMEPATH/scripts/func.sh

 #GET INFO ABOUT SCRIPT
get_info_func $1

 #INIT FILES
WORK_FILES="$BLACKLIST \
            $ROUTE_FORCE_ISP $ROUTE_FORCE_VPN1 \
            $ROUTE_BASE_VPN \
            $MD5_SUM"
INIT=$1
init_files_func $WORK_FILES

 #WAIT DNS
wait_dns_func

 #CHECK AND REPLACE VPN IN BIRD CONF
vpn_bird_func $BIRD_CONF $VPN1

 #BASE_LIST
curl_funk $URLS $BLACKLIST | diff_funk $BLACKLIST -
ipr_func lo $BLACKLIST | diff_funk $ROUTE_BASE_VPN -

 #FORCE_LIST
ipr_func $ISP $ISPTXT | diff_funk $ROUTE_FORCE_ISP -
ipr_func $VPN1 $VPNTXT | diff_funk $ROUTE_FORCE_VPN1 -

 #RESTART BIRD
restart_bird_func

 #CHECK DUPLICATE
check_dupl_func
