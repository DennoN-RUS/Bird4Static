#!/bin/sh

 #USER VARIABLE
DEBUG=0
ISP=ISPINPUT
VPN1=VPN1INPUT
HOMEPATH=HOMEPATHINPUT
SYSTEM_FOLDER=SYSTEMFOLDERINPUT
URL0=URLINPUT

 #SCRIPT VARIABE
BLACKLIST=$HOMEPATH/lists/antifilter.list
ROUTE_FORCE_ISP=$SYSTEM_FOLDER/etc/bird4-force-isp.list
ROUTE_FORCE_VPN1=$SYSTEM_FOLDER/etc/bird4-force-vpn1.list
ROUTE_BASE_VPN1=$SYSTEM_FOLDER/etc/bird4-base-vpn1.list
VPN1TXT=$HOMEPATH/lists/user-vpn.list
ISPTXT=$HOMEPATH/lists/user-isp.list
MD5_SUM=$HOMEPATH/scripts/sum.md5

 #GET AS LIST FUNCTION
get_as_func() {
  as_list=$(awk '/^AS([0-9]{1,5})/{print $1}' "$1")
  if [[ -n "$as_list" ]] ; then 
    for cur_as in $as_list; do
      whois -h whois.radb.net -- "-i origin $cur_as" | awk '/^route:/{print $2}'
    done
      awk '!/^AS([0-9]{1,5})/{print $1}' "$1"
  else
    cat $1
fi
}

 #IPRANGE FUNCTION
ipr_func() {
  if [[ "$DEBUG" == 1 ]]; then ipr_verb="-v"; fi
  if [[ $1 =~ ^\([0-9]{1,3}\.\){3}[0-9]{1,3}$ ]]; then
    get_as_func "$2" | iprange $ipr_verb --print-prefix "route " --print-suffix-nets " via $1;" --print-suffix-ips "/32 via $1;" -
  else
    get_as_func "$2" | iprange $ipr_verb --print-prefix "route " --print-suffix-nets " via \"$1\";" --print-suffix-ips "/32 via \"$1\";" -
  fi
}

 #DIFF FUNCTION
diff_funk() {
  if [[ "$3" == "check" ]]; then
    if grep -q -E "([0-9]{1,3}.){3}[0-9]{1,3}/[0-9]{1,3}" $2; then continue; else return; fi
  fi
  if [[ "$DEBUG" == 1 ]]; then
    patch_file=/tmp/patch_$(echo $1 | awk -F/ '{print $NF}')
    echo "########### $(date) STEP_3: diff $(echo $1 | awk -F/ '{print $NF}' ) ###########"
    diff -u $1 $2 > $patch_file
    cat $patch_file && patch $1 $patch_file && rm $patch_file
  else
    diff -u $1 $2 | patch $1 -
  fi
}

 #INIT FILES
if [[ "$DEBUG" == 1 ]]; then echo "########### $(date) STEP_1: add init files ###########"; fi
WORK_FILES="$BLACKLIST \
            $ROUTE_FORCE_ISP $ROUTE_FORCE_VPN1 \
            $ROUTE_BASE_VPN1 \
            $MD5_SUM"
touch $WORK_FILES
for var in $WORK_FILES; do
  [ -s $var ] || echo 1 > $var
done

 #WAIT DNS
if [[ "$DEBUG" == 1 ]]; then echo "########### $(date) STEP_2: wait dns ###########"; fi
until ADDRS=$(dig +short google.com @localhost -p 53) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done

 #BASE_LIST
curl -sk $URL0 | sort | diff_funk $BLACKLIST - check
ipr_func $VPN1 $BLACKLIST | diff_funk $ROUTE_BASE_VPN1 -

 #FORCE_LIST
ipr_func $ISP $ISPTXT | diff_funk $ROUTE_FORCE_ISP -
ipr_func $VPN1 $VPN1TXT | diff_funk $ROUTE_FORCE_VPN1 -

 #RESTART BIRD
if [[ "$DEBUG" == 1 ]]; then echo "########### $(date) STEP_4: restart bird ###########"; fi
if [ "$(cat $MD5_SUM)" != "$(md5sum $SYSTEM_FOLDER/etc/bird4*)" ]; then
  md5sum $SYSTEM_FOLDER/etc/bird4* > $MD5_SUM
  echo "Restarting bird"
  killall -s SIGHUP bird4
fi 
