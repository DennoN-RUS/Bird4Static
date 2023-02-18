#!/bin/sh

ABSOLUTE_FILENAME=`readlink -f "$0"` && HOME_FOLDER=`dirname "$ABSOLUTE_FILENAME"`
SYSTEM_FOLDER=`echo $HOME_FOLDER | awk -F/opt '{print $1}'`
cd $HOME_FOLDER
chmod -x *.sh
$SYSTEM_FOLDER/bin/git status
$SYSTEM_FOLDER/bin/git pull
chmod +x *.sh
./install.sh -u