#!/bin/sh

LISTS=$HOME/Bird4Static/lists
SCRIPTS=$HOME/Bird4Static/scripts

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

# Installing packages
opkg install bird1-ipv4 curl cron bind-dig iprange

# Create start folders
mkdir -p $SCRIPTS
mkdir -p $LISTS

# Getting the path to run the script
ABSOLUTE_FILENAME=`readlink -f "$0"`
DIRECTORY=`dirname "$ABSOLUTE_FILENAME"`

# Filling script folders and custom sheets

cp $DIRECTORY/Install/$CONFFOLDER/*.sh $SCRIPTS
chmod +x $SCRIPTS/*.sh
cp -i $DIRECTORY/Install/$CONFFOLDER/*.list $LISTS

# Copying the bird configuration file
if [ ! -f "/opt/etc/bird4.conf-opkg" ]; then
  mv /opt/etc/bird4.conf /opt/etc/bird4.conf-opkg;
fi
cp -i $DIRECTORY/Install/$CONFFOLDER/bird4.conf /opt/etc/bird4.conf

# Reading vpn and provider interfaces, replacing in scripts and bird configuration
echo -e "\n----------------------"
ifconfig | grep -B 1 "inet addr" | awk '{print $1$2}' | sed ':a;N;$!ba;s/Link\n/ <--/g;s/inetaddr:/ /g;s/--\n//g'

echo "Enter the name of the provider interface from the list above (for exaple ppp0 or eth3)"
read ISP
sed -i 's/ISPINPUT/'$ISP'/' $SCRIPTS/add-bird4_routes.sh

echo "Enter the VPN interface name from the list above (for exaple ovpn_br0 or nwg0)"
read VPN1
sed -i 's/VPN1INPUT/'$VPN1'/' $SCRIPTS/add-bird4_routes.sh
sed -i 's/VPN1INPUT/'$VPN1'/' /opt/etc/bird4.conf

if [ "$conf" -eq "1" ]; then 
  echo "Enter the Second VPN interface name from the list above (for exaple ovpn_br0 or nwg0)"
  read VPN2
  sed -i 's/VPN2INPUT/'$VPN2'/' $SCRIPTS/add-bird4_routes.sh
  sed -i 's/VPN2INPUT/'$VPN2'/' /opt/etc/bird4.conf
fi

# Organizing scripts into folders
ln -sf $SCRIPTS/bird-table.sh /opt/etc/init.d/S02bird-table
ln -sf $SCRIPTS/add-bird4_routes.sh /opt/etc/cron.hourly/

# Starting Services
/opt/etc/init.d/S02bird-table start
$SCRIPTS/add-bird4_routes.sh
/opt/etc/init.d/S10cron start
/opt/etc/init.d/S04bird1-ipv4 start

exit 0
;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
