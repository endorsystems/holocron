#!/bin/bash
#
# aur.sh
#

# Create AUR dir in $HOME
mkdir -p $HOME/.aur/
## Used to get aur packages installed during ISO install.
# TODO: create list of scripted installs for each

# Polybar?
git clone https://aur.archlinux.org/polybar.git $HOME/.aur/polybar

# RocketChat?
git clone https://aur.archlinux.org/rocketchat-desktop.git $HOME/.aur/rocketchat-desktop