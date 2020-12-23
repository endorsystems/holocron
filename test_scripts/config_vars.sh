#!/bin/bash

### CONFIG VARS ###
# TODO: Put this in a post-condif section? Also need to create escape theads for each question.
# hostname
hostname=$(whiptail --inputbox "Please type the requested hostname." 8 39  --title "Hostname" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Confirmed: ${hostname}"
else
    echo "User Canceled."
fi
# sudo username
sudo_user=$(whiptail --inputbox "Please type the requested sudo user." 8 39  --title "Sudo User" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Confirmed: ${sudo_user}"
else
    echo "User Canceled."
fi
# sudo user passwd
sudo_user_pass=$(whiptail --passwordbox "please enter your secret password for ${sudo_user}" 8 78 --title "Sudo User password dialog" 3>&1 1>&2 2>&3)
                                                                        # A trick to swap stdout and stderr.
# Again, you can pack this inside if, but it seems really long for some 80-col terminal users.
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "${sudo_user} password is set."
else
    echo "User Canceled."
fi

echo "(Exit status was $exitstatus)"
# root user passwd
root_pass=$(whiptail --passwordbox "please enter your secret password for the root user" 8 78 --title "ROOT password dialog" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "root password is set."
else
    echo "User Canceled."
fi

## OLD SCRIPT

# # Device type (laptop, VM, desktop)
# # TODO: Create use cases for this.
# # echo "Input the type of device. (Laptop, VM, Desktop)"
# # read device_type

# # Hostname
# echo "Please type in the desired hostname."
# read hostname
# echo ""

# # Sudoer
# echo "Please enter the name of the super user."
# read sudo_user
# echo " "

# # Sudoer password
# echo "Please enter the password for the super user."
# read -s sudo_user_pass
# echo ""

# # Root pw
# echo "Please type the password for the root user."
# read -s root_pass
# echo ""