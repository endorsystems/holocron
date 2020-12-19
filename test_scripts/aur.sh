#!/bin/bash
#
# aur.sh
#

# Create AUR dir in $HOME
mkdir -p $HOME/.aur/
## Used to get aur packages installed during ISO install.
# TODO: create list of scripted installs for each

# pikaur
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -si

# install packages
pikaur -Sy \
    teams \
    