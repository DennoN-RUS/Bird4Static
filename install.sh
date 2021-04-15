#!/bin/sh

LISTS=$HOME/Bird4Static/lists
SCRIPTS=$HOME/Bird4Static/scripts

while true; do
    echo "Begin install? y/n"
    read yn
    case $yn in
        [Yy]* )

opkg install bird1-ipv4 curl cron bind-dig

mkdir -p $SCRIPTS
mkdir -p $LISTS

cp ./Install/*.sh $SCRIPTS
cp -i ./Install/*.list $LISTS

ifconfig | grep -B 1 "inet addr" | awk '{print $1$2}' | sed ':a;N;$!ba;s/Link\n/ <--/g;s/inetaddr:/ /g;s/--\n//g'
echo "Enter the name of the provider interface from the list above (for exaple ppp0 or eth3)"
read ISP
sed -i 's/ISPINPUT/'$ISP'/' $SCRIPTS/add-bird4_routes.sh
echo "Enter the VPN interface name from the list above (for exaple ovpn_br0 or nwg0)"
read VPN
sed -i 's/VPNINPUT/'$VPN'/' $SCRIPTS/add-bird4_routes.sh

ndmc -c "show interface" | awk '/Inter/ || /addr/' | grep -B 1 "addr" | awk '!/--/' | awk '{print $4$2}' | sed ':a;N;$!ba;s/\"name\n/ <-- /g;s/\"//g'
echo "Enter the VPN interface name from the list above (for exaple OpenVPN0 or Wireguard0)"
read VPNC
sed -i 's/VPNINPUT/'$VPNC'/' $SCRIPTS/addtable.sh

if [ ! -f "/opt/etc/bird4.conf-opkg" ];
  then mv /opt/etc/bird4.conf /opt/etc/bird4.conf-opkg;
fi
cp -i ./Install/bird4.conf /opt/etc/bird4.conf

if [ -z "$(ip rule | awk '/^2150/' )" ]; then
        ip rule add table 1000 priority 2150
fi

chmod +x $SCRIPTS/*.sh
ln -sf $SCRIPTS/add-bird4_routes.sh /opt/etc/cron.daily/
ln -sf $SCRIPTS/addtable.sh /opt/etc/ndm/ifstatechanged.d/010-add_antizapret_route.sh
$SCRIPTS/add-bird4_routes.sh
ln /opt/etc/bird4-routes.list $LISTS/

/opt/etc/init.d/S10cron start
/opt/etc/init.d/S04bird1-ipv4 start

exit 0
;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
