#!/bin/sh

VERSION="v3.6.1"

while true; do
    echo -e "\nBegin install? y/n"
    read yn
    case $yn in
        [Yy]* )

# Update busybox
opkg update
opkg upgrade busybox

# Installing packages
opkg install bird1-ipv4 curl cron bind-dig bind-libs iprange whois diffutils patch

# Getting the path to run the script
ABSOLUTE_FILENAME=`readlink -f "$0"`
HOME_FOLDER=`dirname "$ABSOLUTE_FILENAME"` && HOME_FOLDER_SED=$(echo $HOME_FOLDER | sed 's/\//\\\//g')
LISTS=$HOME_FOLDER/lists
SCRIPTS=$HOME_FOLDER/scripts && SCRIPTS_SED=$(echo $SCRIPTS | sed 's/\//\\\//g')
SYSTEM_FOLDER=`echo $HOME_FOLDER | awk -F/opt '{print $1}'`
SYSTEM_FOLDER=$SYSTEM_FOLDER/opt && SYSTEM_FOLDER_SED=$(echo $SYSTEM_FOLDER | sed 's/\//\\\//g')

# Create start folders
mkdir -p $SCRIPTS
mkdir -p $LISTS

# Filling script folders and custom sheets
echo -e "\nDo you want to use double vpn configuration? 1 - no (default) 2 - yes"
read CONF
if [ "$CONF" != "2" ]; then 
  CONF=1
  CONFFOLDER="one_vpn"
  echo "You are select install for one vpn"
else 
  CONFFOLDER="double_vpn"
  echo "You are select install for double vpn"
fi

cp $HOME_FOLDER/Install/common/*.sh $SCRIPTS
cp $HOME_FOLDER/Install/$CONFFOLDER/*.sh $SCRIPTS
sed -i 's/VERSIONINPUT/'$VERSION'/; s/CONFINPUT/'$CONF'/; s/SCRIPTSINPUT/'$SCRIPTS_SED'/' $SCRIPTS/*.sh
chmod +x $SCRIPTS/*.sh
cp -i $HOME_FOLDER/Install/common/*.list $LISTS
cp -i $HOME_FOLDER/Install/$CONFFOLDER/*.list $LISTS

# Copying the bird configuration file
if [ ! -f "$SYSTEM_FOLDER/etc/bird4.conf-opkg" ]; then
  mv $SYSTEM_FOLDER/etc/bird4.conf $SYSTEM_FOLDER/etc/bird4.conf-opkg;
fi
cp $HOME_FOLDER/Install/$CONFFOLDER/bird4.conf $SYSTEM_FOLDER/etc/bird4.conf

# Getting URL for routing, replacing in scripts
echo -e "\nSelect mode: \n 1 - Download file from antifilter service (default) \n 2 - Use BGP \n 3 - Use Only user files"
read MODE
if [ "$MODE" == "2" ]; then 
  echo "You are select 'BGP mode'"
elif [ "$MODE" == "3" ]; then
  echo "You are select 'File mode'"
else
  MODE=1
  echo "You are select 'Download mode'"
fi
sed -i 's/MODEINPUT/'$MODE'/' $SCRIPTS/*.sh

if [ "$MODE" == "1" ]; then 
  # Download mode
  echo -e "\nWhich service do you want to use\n 1 - https://antifilter.download/list/allyouneed.lst\n 2 - https://antifilter.network/download/ipsmart.lst\n or enter custom url"
  read FILTER
  if [ "$FILTER" == "1" ]; then
    FILTER="https://antifilter.download/list/allyouneed.lst"
  elif [ "$FILTER" == "2" ]; then
    FILTER="https://antifilter.network/download/ipsmart.lst"
  fi
  echo -e "You are select $FILTER"
  FILTER="$(echo $FILTER | sed 's/\//\\\//g')"
  sed -i 's/URLINPUT/'$FILTER'/' $SCRIPTS/*.sh
else
  # File mode
  sed -i '/$BLACKLIST -/s/^/#/; /$ROUTE_BASE_VPN -/s/^/#/' $SCRIPTS/add-bird4_routes.sh
  if [ "$MODE" == "2" ]; then
  # BGP mode
    cat $HOME_FOLDER/Install/common/bird4-bgp.conf >> $SYSTEM_FOLDER/etc/bird4.conf
    echo -e "Which BGP service do you want to use\n 1 - antifilter.download 45.154.73.71 (default) \n 2 - antifilter.network 51.75.66.20 \n 3 - antifilter.network with vpn 10.75.66.20 ( you need install vpn first https://antifilter.network/vpn )"
    read BGP
    if [ "$BGP" == "2" ]; then
      BGP_IP="51.75.66.20" && BGP_AS="65444"
    elif [ "$BGP" == "3" ]; then
      BGP_IP="10.75.66.20" && BGP_AS="65444"
    else
      BGP_IP="45.154.73.71" && BGP_AS="65432"
    fi
    echo -e "You are select BGP $BGP_IP AS$BGP_AS"
    sed -i 's/BPGIPINPUT/'$BGP_IP'/; s/BGPASINPUT/'$BGP_AS'/' $SYSTEM_FOLDER/etc/bird4.conf
    sed -i 's/BPGIPINPUT/'$BGP_IP'/; s/BGPASINPUT/'$BGP_AS'/' $SCRIPTS/*.sh
  fi
fi

# Reading vpn and provider interfaces, replacing in scripts and bird configuration
echo -e "\n----------------------"
ip addr show | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $(NF), $2}'

echo "Enter the name of the provider interface from the list above (for exaple ppp0 or eth3)"
read ISP
sed -i 's/ISPINPUT/'$ISP'/' $SCRIPTS/*.sh
ISP_IP=$(ip addr show $ISP | awk -F" |/" '{gsub(/^ +/,"")}/inet /{print $2}')
if [[ $ISP_IP =~ ^\([0-9]{1,3}\.\){3}[0-9]{1,3}$ ]]; then echo "Your id is $ISP_IP"; else ISP_IP="123.123.123.123"; fi

echo "Enter the VPN interface name from the list above (for exaple ovpn_br0 or nwg0)"
read VPN1
sed -i 's/VPN1INPUT/'$VPN1'/' $SCRIPTS/*.sh
sed -i 's/VPN1INPUT/'$VPN1'/' $SYSTEM_FOLDER/etc/bird4.conf

if [ "$CONF" == "2" ]; then 
  echo "Enter the Second VPN interface name from the list above (for exaple ovpn_br0 or nwg0)"
  read VPN2
  sed -i 's/VPN2INPUT/'$VPN2'/' $SCRIPTS/*.sh
  sed -i 's/VPN2INPUT/'$VPN2'/' $SYSTEM_FOLDER/etc/bird4.conf
fi

sed -i 's/HOMEFOLDERINPUT/'$HOME_FOLDER_SED'/; s/SYSTEMFOLDERINPUT/'$SYSTEM_FOLDER_SED'/' $SCRIPTS/*.sh
sed -i 's/IDINPUT/'$ISP_IP'/' $SYSTEM_FOLDER/etc/bird4.conf

# Organizing scripts into folders
ln -sf $SCRIPTS/bird-table.sh $SYSTEM_FOLDER/etc/init.d/S02bird-table
ln -sf $SCRIPTS/add-bird4_routes.sh $SYSTEM_FOLDER/etc/cron.hourly/

# Remove old generated lists
rm -r $SYSTEM_FOLDER/etc/bird4*.list

# Starting Services
$SYSTEM_FOLDER/etc/init.d/S02bird-table restart
$SCRIPTS/add-bird4_routes.sh -i
$SYSTEM_FOLDER/etc/init.d/S10cron restart
$SYSTEM_FOLDER/etc/init.d/S04bird1-ipv4 restart
$SCRIPTS/add-bird4_routes.sh

exit 0
;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
