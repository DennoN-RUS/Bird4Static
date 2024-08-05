#!/bin/sh

VERSION_NEW="v3.9"

while true; do
    echo -e "\nBegin install? y/n"
    read yn
    case $yn in
        [Yy]* )

# Getting the path to run the script
ABSOLUTE_FILENAME=`readlink -f "$0"`
HOME_FOLDER=`dirname "$ABSOLUTE_FILENAME"` && HOME_FOLDER_SED=$(echo $HOME_FOLDER | sed 's/\//\\\//g')
LISTS=$HOME_FOLDER/lists
SCRIPTS=$HOME_FOLDER/scripts && SCRIPTS_SED=$(echo $SCRIPTS | sed 's/\//\\\//g')
SYSTEM_FOLDER=`echo $HOME_FOLDER | awk -F/opt '{print $1}'`
SYSTEM_FOLDER=$SYSTEM_FOLDER/opt && SYSTEM_FOLDER_SED=$(echo $SYSTEM_FOLDER | sed 's/\//\\\//g')
echo -e "HomeFolder is $HOME_FOLDER \nSystemFolder is $SYSTEM_FOLDER"

source $HOME_FOLDER/Install/install_func.sh

# Installing packages
install_packages_func

# Create start folders
create_folder_func

# Stop service if exist
stop_func

# Print current configuration
print_old_conf

# Try get old config
if [ "$1" == "-u" ]; then UPDATE=1 && get_old_config_func; fi

# Select number vpn
select_number_vpn_func

# Filling script folders and custom sheets
fill_folder_and_sed_func

# Copying the bird configuration file
copy_bird_config_func

# Select mode
select_mode_func
if [ "$MODE" == "1" ]; then configure_download_mode_func; fi
if [ "$MODE" == "2" ]; then configure_bgp_mode_func; fi
if [ "$MODE" == "3" ]; then configure_file_mode_func; fi

# Reading vpn and provider interfaces, replacing in scripts and bird configuration
show_interfaces_func
config_isp_func
config_vpn1_func
if [ "$CONF" == "2" ]; then config_vpn2_func; fi

# Organizing scripts into folders
ln_scripts_func

# Remove old generated lists
rm_old_list_func

# Starting Services
run_func

install_ipset4static

exit 0
;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done