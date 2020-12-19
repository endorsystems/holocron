#!/bin/bash

 if [[ $REPLY =~ ^[Yy]$ ]]
then
# local FS repo
    echo "Using local filesystem repo mounted at /media/archlinux"
    if grep -qs '/media/' /proc/mounts; then
        echo "Server = file:///media/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
    else
        echo "No drive mounted to /media, moving on with defaults..."
    fi
else
    echo "No was selected. Checking for local network mirror"
# Local network repo
    echo "Please enter a local repo IP. Blank will default to basic public."
    echo "Example: 10.0.0.3"
    read repo_url

    if [ -z "$repo_url" ]
    then
        echo "No Repo selected, using defaults."
        echo ""
    else
        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
        echo "Server = http://${repo_url}/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
        echo "Server added, updating repo..."
        pacman -Sy
    fi
fi
