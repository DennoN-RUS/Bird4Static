 #SCRIPT VARIABLE
SYSTEM_FOLDER=SYSTEMFOLDERINPUT
BLACKLIST=$HOMEPATH/lists/antifilter.list
ROUTE_FORCE_ISP=$SYSTEM_FOLDER/etc/bird4-force-isp.list
ROUTE_FORCE_VPN1=$SYSTEM_FOLDER/etc/bird4-force-vpn1.list
ROUTE_FORCE_VPN2=$SYSTEM_FOLDER/etc/bird4-force-vpn2.list
ROUTE_BASE_VPN=$SYSTEM_FOLDER/etc/bird4-base-vpn.list
ROUTE_USER_VPN=$SYSTEM_FOLDER/etc/bird4-user-vpn.list
BIRD_CONF=$SYSTEM_FOLDER/etc/bird4.conf
VPNTXT=$HOMEPATH/lists/user-vpn.list
VPN1TXT=$HOMEPATH/lists/user-vpn1.list
VPN2TXT=$HOMEPATH/lists/user-vpn2.list
ISPTXT=$HOMEPATH/lists/user-isp.list
MD5_SUM=$HOMEPATH/scripts/sum.md5

 #INFO VARIABLE
VERSION=VERSIONINPUT
SCRIPT_FILE=SCRIPTSINPUT/add-bird4_routes.sh
VCONF=CONFINPUT
VHOMEPATH="$(awk -F= '/^HOMEPATH=/{print $2}' $SCRIPT_FILE)"
VMODE=MODEINPUT
VURLS="$(awk -F= '/^URLS=/{print $2}' $SCRIPT_FILE)"
VBGP_IP=BPGIPINPUT && VBGP_AS=BGPASINPUT
VISP="$(awk -F= '/^ISP=/{print $2}' $SCRIPT_FILE)"
VVPN1="$(awk -F= '/^VPN1=/{print $2}' $SCRIPT_FILE)"
VVPN2="$(awk -F= '/^VPN2=/{print $2}' $SCRIPT_FILE)"

 #GET INFO
get_info_func() {
  if [[ "$1" == "-v" ]]; then
    echo "VERSION=$VERSION"
    echo "CONF=$VCONF"
    if [ $VCONF == 1 ]; then echo -e " Use one vpn\n ISP=$VISP VPN=$VVPN1"; else echo -e " Use double vpn\n ISP=$VISP VPN1=$VVPN1 VPN2=$VVPN2"; fi
    echo "MODE=$VMODE"
    if [ $VMODE == 1 ]; then echo -e " Download mode\n URLS=$VURLS";
    elif [ $VMODE == 2 ]; then echo -e " BGP mode\n IP=$VBGP_IP AS=$VBGP_AS";
    else echo " File mode"
    fi
  exit
  fi
}

 #INIT FILES FUNCTION
init_files_func() {
  if [[ "$DEBUG" == 1 ]]; then echo -e "\n########### $(date) STEP_2: add init files ###########\n" >&2; fi
  for file in $@; do if [ ! -f $file ]; then touch $file; fi; done
  if [[ "$INIT" == "-i" ]]; then exit; fi
}

 #WAIT DNS FUNCTION
wait_dns_func() {
  if [[ "$DEBUG" == 1 ]]; then echo -e "\n########### $(date) STEP_1: wait dns ###########\n" >&2; fi
  until ADDRS=$(dig +short google.com @localhost -p 53) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done 
} 

 #check VPN in bird config
vpn_bird_func() {
  if [ "$(grep -c "ifname = \"$2\"; #MARK_VPN1" $1)" == 0 ]; then sed -i '/#MARK_VPN1/s/".*"/"'$2'"/' $1; fi
  if [ "$#" == 2 ]; then
    if [ "$(grep -c "interface \"$2\"" $1)" == 0 ]; then sed -i '/interface/s/".*"/"'$2'"/' $1; fi
  elif [ "$#" == 3 ]; then
    if [ "$(grep -c "interface \"$2\", \"$3\"" $1)" == 0 ]; then sed -i '/interface/s/".*", ".*"/"'$2'", "'$3'"/' $1; fi
    if [ "$(grep -c "ifname = \"$3\"; #MARK_VPN2" $1)" == 0 ]; then sed -i '/#MARK_VPN2/s/".*"/"'$3'"/' $1; fi
  fi
}

 #CURL FUNCTION
curl_funk() {
  for var in $@; do
    if [[ $var =~ ^http ]]; then cur_url=$(echo "$cur_url $var"); else last=$var; fi
  done
  if [ "$(curl -s $cur_url | grep -E '([0-9]{1,3}.){3}[0-9]{1,3}')" ]; then curl -s $cur_url | sort ; else cat $last; fi
}

 #DIFF FUNCTION
diff_funk() {
  if [[ "$DEBUG" == 1 ]]; then
    patch_file=/tmp/patch_$(echo $1 | awk -F/ '{print $NF}')
    echo -e "\n########### $(date) STEP_3: diff $(echo $1 | awk -F/ '{print $NF}' ) ###########\n" >&2
    diff -u $1 $2 > $patch_file
    cat $patch_file && patch $1 $patch_file
  else
    diff -u $1 $2 | patch $1 -
  fi
}

 #GET AS LIST FUNCTION
get_as_func() {
  as_list=$(awk '/^AS([0-9]{1,5})/{print $1}' "$1")
  if [[ -n "$as_list" ]] ; then 
    if [[ "$DEBUG" == 1 ]]; then echo -e "\n########### $(date) STEP_X: get as from file $(echo $1 | awk -F/ '{print $NF}' ) ###########\n" >&2; fi
    for cur_as in $as_list; do
      if [[ "$DEBUG" == 1 ]]; then out=2; echo -e "\n$cur_as" >&$out; fi
      for i in $out 1; do
        curl -s https://stat.ripe.net/data/announced-prefixes/data.json?resource=$cur_as | awk -F '"' '/([0-9]{1,3}.){3}[0-9]{1,3}\/[0-9]{1,2}/{print $4}' | iprange - >&$i
       done
    done
      awk '!/^AS([0-9]{1,5})/{print $0}' "$1"
  else
    cat $1
fi
}

 #IPRANGE FUNCTION
ipr_func() {
  if [[ $1 =~ ^\([0-9]{1,3}\.\){3}[0-9]{1,3}$ ]]; then cur_gw=$1 ; else cur_gw=\"$1\"; fi
  if [[ "$DEBUG" == 1 ]]; then ipr_verb="-v"; echo -e "\n########### $(date) STEP_4: ipr func file $(echo $2 | awk -F/ '{print $NF}' ) ###########\n" >&2; fi
  get_as_func "$2" | iprange $ipr_verb --print-prefix "route " --print-suffix-nets " via $cur_gw;" --print-suffix-ips "/32 via $cur_gw;" -
}

 #RESTART BIRD FUNCTION
restart_bird_func() {
  if [[ "$DEBUG" == 1 ]]; then echo -e "\n########### $(date) STEP_5: restart bird ###########\n" >&2; fi
  if [ "$(cat $MD5_SUM)" != "$(md5sum $SYSTEM_FOLDER/etc/bird4*)" ]; then
    md5sum $SYSTEM_FOLDER/etc/bird4* > $MD5_SUM
    echo "Restarting bird"
    killall -s SIGHUP bird4
  fi
}

 #CHECK DUPLICATE IN ROUTES FUNCTION
check_dupl_func(){
  dupl_route=$(sort -m $SYSTEM_FOLDER/etc/bird4-force*.list | awk '{print $2}' | uniq -d | grep -Fw -f - $SYSTEM_FOLDER/etc/bird4-force*.list)
  if [[ -n "$dupl_route" ]]; then
    echo "DUPLICATE IN FILES"
    echo $dupl_route | sed 's/; /;\n/g' -
  fi
}