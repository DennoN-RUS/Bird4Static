#!/bin/sh

ABSOLUTE_FILENAME=`readlink -f "$0"` && HOME_FOLDER=`dirname "$ABSOLUTE_FILENAME"`
cd $HOME_FOLDER
chmod -x *.sh
git status
git pull
chmod +x *.sh
./install.sh