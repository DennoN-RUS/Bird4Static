 #WAIT DNS FUNCTION
wait_dns_func() {
  if [[ "$DEBUG" == 1 ]]; then echo -e "\n########### $(date) STEP_1: wait dns ###########\n" >&2; fi
  until ADDRS=$(dig +short google.com @localhost -p 53) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done 
} 

 #INIT FILES FUNCTION
init_files_func() {
  if [[ "$DEBUG" == 1 ]]; then echo -e "\n########### $(date) STEP_2: add init files ###########\n" >&2; fi
  touch $@
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

 #CURL FUNCTION
curl_funk() {
  if [[ "$DISABLE_URLS" == 0 ]]; then
    for var in $@; do
      if [[ $var =~ ^http ]]; then cur_url=$(echo "$cur_url $var"); else last=$var; fi
    done
    if [ "$(curl -s $cur_url | grep -E '([0-9]{1,3}.){3}[0-9]{1,3}')" ]; then curl -s $cur_url | sort ; else cat $last; fi
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
