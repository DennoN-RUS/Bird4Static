#!/bin/sh

ABSOLUTE_FILENAME=`readlink -f "$0"`
HOME_FOLDER=`dirname "$ABSOLUTE_FILENAME"` && HOME_FOLDER_SED=$(echo $HOME_FOLDER | sed 's/\//\\\//g')
LISTS=$HOME_FOLDER/lists
SCRIPTS=$HOME_FOLDER/scripts
SYSTEM_FOLDER=`echo $HOME_FOLDER | awk -F/opt '{print $1}'`
SYSTEM_FOLDER=$SYSTEM_FOLDER/opt && SYSTEM_FOLDER_SED=$(echo $SYSTEM_FOLDER | sed 's/\//\\\//g')

SCRIPTS=$HOME_FOLDER/scripts

while true; do
    echo "Begin uninstall? y/n"
    read yn
    case $yn in
        [Yy]* )

# Stop Services
$SYSTEM_FOLDER/etc/init.d/S02bird-table stop
$SYSTEM_FOLDER/etc/init.d/S04bird1-ipv4 stop

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
if [ "$answer" = "1" ]; then opkg remove bind-dig bind-libs; fi
# iprange
answer=0; echo "Do you want remove 'iprange'? 0 - no 1 - yes (default: no)"; read answer
if [ "$answer" = "1" ]; then opkg remove iprange; fi
# whois
answer=0; echo "Do you want remove 'whois'? 0 - no 1 - yes (default: no)"; read answer
if [ "$answer" = "1" ]; then opkg remove whois; fi
# diff and patch
answer=0; echo "Do you want remove 'diffutils' and 'patch'? 0 - no 1 - yes (default: no)"; read answer
if [ "$answer" = "1" ]; then opkg remove diffutils patch; fi

# Remove start folders
rm -r $SCRIPTS

# Remove scripts into folders
rm $SYSTEM_FOLDER/etc/init.d/S02bird-table
rm $SYSTEM_FOLDER/etc/cron.hourly/add-bird4_routes.sh

# Remove bird lists
rm -r $SYSTEM_FOLDER/etc/bird4*.list

exit 0
;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
