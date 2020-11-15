#!/bin/sh

opkg install bird1-ipv4 curl cron bind-dig

chmod +x Bird4Static/root/addip.sh
chmod +x Bird4Static/etc/ndm/ifstatechanged.d/010-add_antizapret_route.sh
chmod +x Bird4Static/etc/cron.daily/add-bird4_routes.sh
cp /opt/etc/bird4.conf /opt/etc/bird4.conf-opkg
cp -rf Bird4Static/etc/ /opt/
cp -rf Bird4Static/root/ /opt/

if [ -z "$(ip rule | grep 1000)" ]; then
  ip rule add table 1000
fi

ifconfig | grep -B 1 "inet addr" | awk '{print $1$2}' | sed ':a;N;$!ba;s/Link\n/ <--/g;s/inetaddr:/ /g;s/--\n//g'
echo "Введите имя интерфейса провайдера из списка выше (например, ppp0 или eth3)"
read ISP
sed -i 's/eth3/'$ISP'/' /opt/etc/cron.daily/add-bird4_routes.sh
echo "Введите имя интерфейса VPN из списка выше (например, ppp1 или nwg0)"
read VPN
sed -i 's/ppp0/'$VPN'/' /opt/etc/cron.daily/add-bird4_routes.sh

ndmc -c "show interface" | awk '/Inter/ || /addr/' | grep -B 1 "addr" | awk '!/--/' | awk '{print $4$2}' | sed ':a;N;$!ba;s/\"name\n/ <-
- /g;s/\"//g'
echo "Введите имя интерфейса VPN из списка выше (например, IKE0 или L2TP0)"
read VPNC
sed -i 's/L2TP0/'$VPNC'/' /opt/etc/ndm/ifstatechanged.d/010-add_antizapret_route.sh

echo "Введите IP-адрес удаленного сервера, где поднят VPN"

while :; do
  read VPNIP

  if expr "$VPNIP" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
    for i in 1 2 3 4; do
      if [ $(echo "$VPNIP" | cut -d. -f$i) -gt 255 ]; then
        echo "Введен некорректный IP-адрес. Повторите ввод"
        continue 2
      fi
    done
    break
  else
    echo "Введен некорректный IP-адрес. Повторите ввод"
  fi
done

sed -i 's/#route.*/route '$VPNIP'\/32 via "'$ISP'";/' /opt/etc/bird4.conf

/opt/etc/cron.daily/add-bird4_routes.sh

/opt/etc/init.d/S10cron start
/opt/etc/init.d/S04bird1-ipv4 start

exit 0