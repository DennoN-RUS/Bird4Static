#!/bin/sh

ABSOLUTE_FILENAME=`readlink -f "$0"` && HOME_FOLDER=`dirname "$ABSOLUTE_FILENAME"`
SYSTEM_FOLDER=`echo $HOME_FOLDER | awk -F/opt '{print $1}'` && SYSTEM_FOLDER=$SYSTEM_FOLDER/opt
cd $HOME_FOLDER
$SYSTEM_FOLDER/bin/git restore *.sh Install/*
$SYSTEM_FOLDER/bin/git status
$SYSTEM_FOLDER/bin/git pull
chmod +x *.sh
sh ./install.sh -u