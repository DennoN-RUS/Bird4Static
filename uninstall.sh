#!/bin/sh

SCRIPTS=$HOME/Bird4Static/scripts

while true; do
    echo "Begin uninstall? y/n"
    read yn
    case $yn in
        [Yy]* )

# Stop Services
/opt/etc/init.d/S02bird-table stop
/opt/etc/init.d/S04bird1-ipv4 stop

# Remove packages
# bird
opkg remove bird1-ipv4
# curl
answer=0; echo "Do you want remove 'curl'? 0 - no 1 - yes (default: no)"; read answer
if [ "$answer" = "1" ]; then opkg remove curl; fi
# cron
answer=0; echo "Do you want remove 'cron'? 0 - no 1 - yes (default: no)"; read answer
if [ "$answer" = "1" ]; then opkg remove cron; fi
# bind-dig
answer=0; echo "Do you want remove 'bind-dig'? 0 - no 1 - yes (default: no)"; read answer
if [ "$answer" = "1" ]; then opkg remove bind-dig; fi
# iprange
answer=0; echo "Do you want remove 'iprange'? 0 - no 1 - yes (default: no)"; read answer
if [ "$answer" = "1" ]; then opkg remove iprange; fi
# whois
answer=0; echo "Do you want remove 'whois'? 0 - no 1 - yes (default: no)"; read answer
if [ "$answer" = "1" ]; then opkg remove whois; fi

# Remove start folders
rm -r $SCRIPTS

# Remove scripts into folders
rm /opt/etc/init.d/S02bird-table
rm /opt/etc/cron.hourly/add-bird4_routes.sh

# Remove bird lists
rm -r /opt/etc/bird4*.list

exit 0
;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
