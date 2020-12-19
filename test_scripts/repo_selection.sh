#!/bin/bash

### REPO SETUP ###
# TODO: Create an updated repo selection.
# Repo selection will include an offline USB selection, Local network mirror, default mirror.

# Input box for repo selection
repo_url=$(whiptail --inputbox "Please type your desired repo url.\nExample:\nLocalfile: file:///media/archlinux/\nLocal Network: http://<IP>/archlinux/\nCancel for default." 11 70  --title "Repo Selection" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    # Backup old repo
    cp /etc/pacman.d/mirrorlist ~/
    # Install Selected repo
    echo "Server = ${repo_url}/\$repo/os/\$arch/" > /etc/pacman.d/mirrorlist
    # Update pacman cache
    pacman -Sy
else
    echo "User Canceled. Using default settings."
fi

# echo ${repo_url}
# echo "(Exit status was ${exitstatus})"


### OLD SCRIPT ###
# if [[ $REPLY =~ ^[Yy]$ ]]
# then
# # local FS repo
#     echo "Using local filesystem repo mounted at /media/archlinux"
#     if grep -qs '/media/' /proc/mounts; then
#         echo "Server = file:///media/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
#     else
#         echo "No drive mounted to /media, moving on with defaults..."
#     fi
# else
#     echo "No was selected. Checking for local network mirror"
# # Local network repo
#     echo "Please enter a local repo IP. Blank will default to basic public."
#     echo "Example: 10.0.0.3"
#     read repo_url

#     if [ -z "$repo_url" ]
#     then
#         echo "No Repo selected, using defaults."
#         echo ""
#     else
#         cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
#         echo "Server = http://${repo_url}/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
#         echo "Server added, updating repo..."
#         pacman -Sy
#     fi
# fi
