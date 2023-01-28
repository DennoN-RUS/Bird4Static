#!/bin/sh

while true; do
    echo "Begin install? y/n"
    read yn
    case $yn in
        [Yy]* )

echo "Do you want to use double vpn configuration? 0 - no (default) 1 - yes"
read conf
if [ "$conf" != "1" ]; then 
  conf=0
  CONFFOLDER="one_vpn"
  echo "Starting install for one vpn"
else 
  CONFFOLDER="double_vpn"
  echo "Starting install for double vpn"
fi

# Update busybox
opkg update
opkg upgrade busybox

# Installing packages
opkg install bird1-ipv4 curl cron bind-dig bind-libs iprange whois

# Getting the path to run the script
ABSOLUTE_FILENAME=`readlink -f "$0"`
HOME_FOLDER=`dirname "$ABSOLUTE_FILENAME"` && HOME_FOLDER_SED=$(echo $HOME_FOLDER | sed 's/\//\\\//g')
LISTS=$HOME_FOLDER/lists
SCRIPTS=$HOME_FOLDER/scripts
SYSTEM_FOLDER=`echo $HOME_FOLDER | awk -F/opt '{print $1}'`
SYSTEM_FOLDER=$SYSTEM_FOLDER/opt && SYSTEM_FOLDER_SED=$(echo $SYSTEM_FOLDER | sed 's/\//\\\//g')

# Create start folders
mkdir -p $SCRIPTS
mkdir -p $LISTS

# Filling script folders and custom sheets

cp $HOME_FOLDER/Install/common/*.sh $SCRIPTS
cp $HOME_FOLDER/Install/$CONFFOLDER/*.sh $SCRIPTS
chmod +x $SCRIPTS/*.sh
cp -i $HOME_FOLDER/Install/common/*.list $LISTS
cp -i $HOME_FOLDER/Install/$CONFFOLDER/*.list $LISTS

# Copying the bird configuration file
if [ ! -f "$SYSTEM_FOLDER/etc/bird4.conf-opkg" ]; then
  mv $SYSTEM_FOLDER/etc/bird4.conf $SYSTEM_FOLDER/etc/bird4.conf-opkg;
fi
cp $HOME_FOLDER/Install/$CONFFOLDER/bird4.conf $SYSTEM_FOLDER/etc/bird4.conf

# Getting URL for routing, replacing in scripts
echo -e "Witch service do you want to use\n 1 - https://antifilter.download/list/allyouneed.lst\n 2 - https://antifilter.network/download/ipsmart.lst\n or enter custom url"
read FILTER
if [ "$FILTER" == "1" ]; then
  sed -i 's/URLINPUT/https:\/\/antifilter.download\/list\/allyouneed.lst/' $SCRIPTS/add-bird4_routes.sh
elif [ "$FILTER" == "2" ]; then
  sed -i 's/URLINPUT/https:\/\/antifilter.network\/download\/ipsmart.lst/' $SCRIPTS/add-bird4_routes.sh
else
  FILTER=$(echo $FILTER | sed 's/\//\\\//g')
  sed -i 's/URLINPUT/'$FILTER'/' $SCRIPTS/add-bird4_routes.sh
fi

# Reading vpn and provider interfaces, replacing in scripts and bird configuration
echo -e "\n----------------------"
ifconfig | grep -B 1 "inet " | awk '{print $1,$2}' | sed ':a;N;$!ba;s/\n//g;s/\--/\n/g' | awk '{print $1,$(NF)}'

echo "Enter the name of the provider interface from the list above (for exaple ppp0 or eth3)"
read ISP
sed -i 's/ISPINPUT/'$ISP'/' $SCRIPTS/add-bird4_routes.sh

echo "Enter the VPN interface name from the list above (for exaple ovpn_br0 or nwg0)"
read VPN1
sed -i 's/VPN1INPUT/'$VPN1'/' $SCRIPTS/add-bird4_routes.sh
sed -i 's/VPN1INPUT/'$VPN1'/' $SYSTEM_FOLDER/etc/bird4.conf

if [ "$conf" -eq "1" ]; then 
  echo "Enter the Second VPN interface name from the list above (for exaple ovpn_br0 or nwg0)"
  read VPN2
  sed -i 's/VPN2INPUT/'$VPN2'/' $SCRIPTS/add-bird4_routes.sh
  sed -i 's/VPN2INPUT/'$VPN2'/' $SYSTEM_FOLDER/etc/bird4.conf
fi

sed -i 's/HOMEPATHINPUT/'$HOME_FOLDER_SED'/' $SCRIPTS/add-bird4_routes.sh
sed -i 's/SYSTEMFOLDERINPUT/'$SYSTEM_FOLDER_SED'/' $SCRIPTS/add-bird4_routes.sh
sed -i 's/SYSTEMFOLDERINPUT/'$SYSTEM_FOLDER_SED'/g' $SYSTEM_FOLDER/etc/bird4.conf

# Organizing scripts into folders
ln -sf $SCRIPTS/bird-table.sh $SYSTEM_FOLDER/etc/init.d/S02bird-table
ln -sf $SCRIPTS/add-bird4_routes.sh $SYSTEM_FOLDER/etc/cron.hourly/

# Starting Services
$SYSTEM_FOLDER/etc/init.d/S02bird-table start
$SCRIPTS/add-bird4_routes.sh
$SYSTEM_FOLDER/etc/init.d/S10cron start
$SYSTEM_FOLDER/etc/init.d/S04bird1-ipv4 start

exit 0
;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
