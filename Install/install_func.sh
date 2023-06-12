install_packages_func(){
  # Update busybox
  $SYSTEM_FOLDER/bin/opkg update
  $SYSTEM_FOLDER/bin/opkg upgrade busybox
  # Installing packages
  $SYSTEM_FOLDER/bin/opkg install bird2 bird2c curl cron bind-dig bind-libs iprange whois diffutils patch
}

# Create start folders
create_folder_func(){
  mkdir -p $SCRIPTS
  mkdir -p $LISTS
}

# Stop service if exist
stop_func(){
  if [ -f "$SYSTEM_FOLDER/etc/init.d/S04bird1-ipv4" ]; then
    echo "Stop bird"
    $SYSTEM_FOLDER/etc/init.d/S04bird1-ipv4 stop
    $SYSTEM_FOLDER/bin/opkg --force-removal-of-dependent-packages remove bird1-ipv4
    rm $SYSTEM_FOLDER/etc/bird4.conf
    install_packages_func
  fi
  if [ -f "$SYSTEM_FOLDER/etc/init.d/S70bird" ]; then
    echo "Stop bird2"
    $SYSTEM_FOLDER/etc/init.d/S70bird stop
  fi
  if [ -f "$SYSTEM_FOLDER/etc/init.d/S02bird-table" ]; then
    echo "Stop bird-table"
    $SYSTEM_FOLDER/etc/init.d/S02bird-table stop
  fi
}

# Print current configuration
print_old_conf(){
  if [ -f "$SCRIPTS/add-bird4_routes.sh" ]; then
    echo -e "\nYour current config is:"
    $SCRIPTS/add-bird4_routes.sh -v
  fi
}

# Try get old config
get_old_config_func(){
  if [ -f "$SCRIPTS/func.sh" ]; then
    source $SCRIPTS/func.sh
    if [ -n "$VCONF" ]; then CONF="$VCONF"; fi
    if [ -n "$VMODE" ]; then MODE="$VMODE"; fi
    if [ -n "$VURLS" ]; then FILTER="$(echo $VURLS | sed 's/"//g')"; fi
    if [ -n "$VBGP_IP" ]; then BGP_IP="$VBGP_IP"; fi
    if [ -n "$VBGP_AS" ]; then BGP_AS="$VBGP_AS"; fi
    if [ -n "$VISP" ]; then ISP="$VISP"; fi
    if [ -n "$VVPN1" ]; then VPN1="$VVPN1"; fi
    if [ -n "$VVPN2" ]; then VPN2="$VVPN2"; fi
  fi
}

# Select number vpn
select_number_vpn_func(){
  if [ -z "$CONF" ]; then
    echo -e "\nDo you want to use double vpn configuration? 1 - no (default) 2 - yes"
    read CONF
  fi
  if [ "$CONF" != "2" ]; then 
    CONF=1
    CONFFOLDER="one_vpn"
    echo "You are select install for one vpn"
  else 
    CONFFOLDER="double_vpn"
    echo "You are select install for double vpn"
  fi
}

# Filling script folders and custom sheets
fill_folder_and_sed_func(){
  cp $HOME_FOLDER/Install/common/*.sh $SCRIPTS
  cp $HOME_FOLDER/Install/$CONFFOLDER/*.sh $SCRIPTS
  chmod +x $SCRIPTS/*.sh
  if [ "$UPDATE" != "1" ]; then
    cp -i $HOME_FOLDER/Install/common/*.list $LISTS
    if [ "$CONF" == "2" ]; then cp -i $HOME_FOLDER/Install/$CONFFOLDER/*.list $LISTS; fi
  fi
  sed -i 's/VERSIONINPUT/'$VERSION'/; s/CONFINPUT/'$CONF'/; s/SCRIPTSINPUT/'$SCRIPTS_SED'/' $SCRIPTS/*.sh
  sed -i 's/HOMEFOLDERINPUT/'$HOME_FOLDER_SED'/; s/SYSTEMFOLDERINPUT/'$SYSTEM_FOLDER_SED'/' $SCRIPTS/*.sh
}

# Copying the bird configuration file
copy_bird_config_func(){
  if [ ! -f "$SYSTEM_FOLDER/etc/bird.conf-opkg" ]; then
    mv $SYSTEM_FOLDER/etc/bird.conf $SYSTEM_FOLDER/etc/bird.conf-opkg;
  fi
  cp $HOME_FOLDER/Install/$CONFFOLDER/bird.conf $SYSTEM_FOLDER/etc/bird.conf
}

# Select mode
select_mode_func(){
  if [ -z "$MODE" ]; then
    echo -e "\nSelect mode: \n 1 - Download file from antifilter service (default) \n 2 - Use BGP \n 3 - Use Only user files"
    read MODE
  fi
  if [ "$MODE" == "2" ]; then 
    echo "You are select 'BGP mode'"
  elif [ "$MODE" == "3" ]; then
    echo "You are select 'File mode'"
  else
    MODE=1
    echo "You are select 'Download mode'"
  fi
  sed -i 's/MODEINPUT/'$MODE'/' $SCRIPTS/*.sh
}

# Download mode
configure_download_mode_func(){
  if [ -z "$FILTER" ]; then
    echo -e "\nWhich service do you want to use\n 1 - https://antifilter.download/list/allyouneed.lst\n 2 - https://antifilter.network/download/ipsmart.lst\n or enter custom url"
    read FILTER
    if [ "$FILTER" == "1" ]; then
      FILTER="https://antifilter.download/list/allyouneed.lst"
    elif [ "$FILTER" == "2" ]; then
      FILTER="https://antifilter.network/download/ipsmart.lst"
    fi
  fi
  echo -e "You are select $FILTER"
  FILTER="$(echo $FILTER | sed 's/\//\\\//g; s/"//g')"
  sed -i 's/URLINPUT/'$FILTER'/' $SCRIPTS/*.sh
}

# File mode
configure_file_mode_func(){
  sed -i '/$BLACKLIST -/s/^/#/; /$ROUTE_BASE_VPN -/s/^/#/' $SCRIPTS/add-bird4_routes.sh
}

# BGP mode
configure_bgp_mode_func(){
  configure_file_mode_func
  cat $HOME_FOLDER/Install/common/bird-bgp.conf >> $SYSTEM_FOLDER/etc/bird.conf
  if [ "$1" != "-u" ] && [ -z "$BGP_IP" ] && [ -z "$BGP_AS" ]; then
    echo -e "Which BGP service do you want to use\n 1 - antifilter.download 45.154.73.71 (default) \n 2 - antifilter.network 51.75.66.20 \n 3 - antifilter.network with vpn 10.75.66.20 ( you need install vpn first https://antifilter.network/vpn )"
    read BGP
    if [ "$BGP" == "2" ]; then
      BGP_IP="51.75.66.20" && BGP_AS="65444"
    elif [ "$BGP" == "3" ]; then
      BGP_IP="10.75.66.20" && BGP_AS="65444"
    else
      BGP_IP="45.154.73.71" && BGP_AS="65432"
    fi
  fi
  echo -e "You are select BGP $BGP_IP AS$BGP_AS"
  sed -i 's/BPGIPINPUT/'$BGP_IP'/; s/BGPASINPUT/'$BGP_AS'/' $SYSTEM_FOLDER/etc/bird.conf
  sed -i 's/BPGIPINPUT/'$BGP_IP'/; s/BGPASINPUT/'$BGP_AS'/' $SCRIPTS/*.sh
}

# Show interfaces
show_interfaces_func(){
  echo -e "\n----------------------"
  ip addr show | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $(NF), $2}'
}

# Config ISP
config_isp_func(){
  if [ -z "$ISP" ]; then
    echo "Enter the name of the provider interface from the list above (for exaple ppp0 or eth3)"
    read ISP
  fi
  echo "Your are select ISP $ISP"
  ISP_IP=$(ip addr show $ISP | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $2}')
  if [ $(echo "$ISP_IP" | grep -cE '^([0-9]{1,3}.){3}[0-9]{1,3}$' ) != 0 ]; then 
    echo "Your id is $ISP_IP"; 
  else 
    ISP_IP="123.123.123.123";
  fi
  sed -i 's/ISPINPUT/'$ISP'/' $SCRIPTS/*.sh
  sed -i 's/IDINPUT/'$ISP_IP'/' $SYSTEM_FOLDER/etc/bird.conf
}

# Config VPN1
config_vpn1_func(){
  if [ -z "$VPN1" ]; then
    echo "Enter the VPN interface name from the list above (for exaple ovpn_br0 or nwg0)"
    read VPN1
  fi
  echo "Your are select VPN1 $VPN1"
  sed -i 's/VPN1INPUT/'$VPN1'/' $SCRIPTS/*.sh
  sed -i 's/VPN1INPUT/'$VPN1'/' $SYSTEM_FOLDER/etc/bird.conf
}

# Config VPN2
config_vpn2_func(){
  if [ -z "$VPN2" ]; then
    echo "Enter the Second VPN interface name from the list above (for exaple ovpn_br0 or nwg0)"
    read VPN2
  fi
  echo "Your are select VPN2 $VPN2"
  sed -i 's/VPN2INPUT/'$VPN2'/' $SCRIPTS/*.sh
  sed -i 's/VPN2INPUT/'$VPN2'/' $SYSTEM_FOLDER/etc/bird.conf
}

# Organizing scripts into folders
ln_scripts_func(){
  ln -sf $SCRIPTS/bird-table.sh $SYSTEM_FOLDER/etc/init.d/S02bird-table
  ln -sf $SCRIPTS/add-bird4_routes.sh $SYSTEM_FOLDER/etc/cron.hourly/
}

# Remove old generated lists
rm_old_list_func(){
  find $SYSTEM_FOLDER/etc/ -type f -name bird4*.list -exec rm -f {} \;
  if [ -f $SCRIPTS/sum.md5 ]; then
    rm $SCRIPTS/sum.md5
  fi
}

# Starting Services
run_func(){
  $SYSTEM_FOLDER/etc/init.d/S02bird-table restart
  $SCRIPTS/add-bird4_routes.sh -i
  $SYSTEM_FOLDER/etc/init.d/S10cron restart
  $SYSTEM_FOLDER/etc/init.d/S70bird restart
  $SCRIPTS/add-bird4_routes.sh
}