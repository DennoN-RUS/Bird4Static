 #WAIT DNS FUNCTION
wait_dns_func() {
  if [[ "$DEBUG" == 1 ]]; then echo -e "\n########### $(date) STEP_1: wait dns ###########\n"; fi
  until ADDRS=$(dig +short google.com @localhost -p 53) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done 
} 

 #INIT FILES FUNCTION
init_files_func() {
  if [[ "$DEBUG" == 1 ]]; then echo -e "\n########### $(date) STEP_2: add init files ###########\n"; fi
  touch $1
  for var in $1; do
    [ -s $var ] || echo 1 > $var
  done
}

 #GET AS LIST FUNCTION
get_as_func() {
  as_list=$(awk '/^AS([0-9]{1,5})/{print $1}' "$1")
  if [[ -n "$as_list" ]] ; then 
    for cur_as in $as_list; do
      curl -s https://stat.ripe.net/data/announced-prefixes/data.json?resource=$cur_as | awk -F '"' '/([0-9]{1,3}.){3}[0-9]{1,3}\/[0-9]{1,2}/{print $4}'
    done
      awk '!/^AS([0-9]{1,5})/{print $0}' "$1"
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
    if grep -q -E "([0-9]{1,3}.){3}[0-9]{1,3}" $2; then continue; else return; fi
  fi
  if [[ "$DEBUG" == 1 ]]; then
    patch_file=/tmp/patch_$(echo $1 | awk -F/ '{print $NF}')
    echo -e "\n########### $(date) STEP_3: diff $(echo $1 | awk -F/ '{print $NF}' ) ###########\n"
    diff -u $1 $2 > $patch_file
    cat $patch_file && patch $1 $patch_file && rm $patch_file
  else
    diff -u $1 $2 | patch $1 -
  fi
}

 #RESTART BIRD FUNCTION
restart_bird_func() {
  if [[ "$DEBUG" == 1 ]]; then echo -e "\n########### $(date) STEP_4: restart bird ###########\n"; fi
  if [ "$(cat $MD5_SUM)" != "$(md5sum $SYSTEM_FOLDER/etc/bird4*)" ]; then
    md5sum $SYSTEM_FOLDER/etc/bird4* > $MD5_SUM
    echo "Restarting bird"
    killall -s SIGHUP bird4
  fi
}
