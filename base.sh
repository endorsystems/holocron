#!/bin/bash
#
# Holocron Arch Linux installer
#

## Starting this script using simple prompts.
# TODO: Replace with interactive whiptail prompts.
# echo "Laptop or VM / Desktop?"
# read device_type

# Hostname
echo "Please type in the desired hostname."
read hostname

# Sudoer
echo "Please enter the name of the super user."
read sudo_user

# Sudoer password
echo "Please enter the password for the super user."
read -s sudo_user_pass

# Root pw
echo "Please type the password for the root user."
read -s root_pass

# Disk Selection
echo `lsblk | grep disk`
echo "Please select from the above disks to use for installation. Make sure its full path '/dev/sda'" 
read disk
if [ -z "$disk" ]
then
      echo "No disk selected, please restart the script."
      exit 1
fi
read -p "Are you sure? THIS WILL DELETE ALL DATA FROM THE SELECTED DISK! (Yes or No)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Disk partitioning.
    parted --script "${disk}" -- mklabel gpt \
    mkpart ESP fat32 1Mib 513MiB \
    set 1 boot on \
    mkpart primary xfs 513MiB 100%
else
    exit 2
fi

# vars
# TODO: look into why this isn't showing the right var
# part_boot="$(lsblk ${disk}* | grep -E "^${disk}p?1$")"
# part_root="$(lsblk ${disk}* | grep -E "^${disk}p?2$")"

# TODO: encryption...

# Formatting
mkfs.fat -F32 "${disk}1"
mkfs.xfs -f "${disk}2"

# Mounting
mount "${disk}2" /mnt
mkdir /mnt/boot
mount "${disk}1" /mnt/boot

## Using templates for either laptop or desktop.
# Package template
# TODO: check this template system out, for now default packages for laptop
# if [[ $device_type == "laptop" ]]
# then
#     # Laptop Template
# fi

# Package installation
# packages=`source vars/laptop_packages`
pacstrap /mnt \
    base \
    base-devel \
    linux \
    linux-firmware \
    linux-headers \
    device-mapper \
    man-db \
    man-pages \
    python \
    python-pip \
    vim \
    diffutils \
    xfsprogs \
    e2fsprogs \
    sysfsutils \
    usbutils \
    inetutils \
    networkmanager \
    network-manager-applet \
    nm-connection-editor \
    cups \
    cups-pdf \
    nss-mdns \
    avahi \
    sane \
    xsane \
    virtualbox \
    docker \
    docker-compose \
    vagrant \
    minikube \
    alsa \
    pulseaudio \
    pulseaudio-alsa \
    pulseaudio-bluetooth \
    pulseaudio-equalizer \
    pulsemixer \
    playerctl \
    chromium \
    samba \
    ufw \
    duplicity \
    git \
    openssh \
    ttf-dejavu \
    ttf-hack \
    ttf-liberation \
    noto-fonts \
    rsync \
    neofetch \
    gnome-calculator \
    caprine \
    eog \
    tmux \
    thunar \
    tumbler \
    grim \
    dmidecode \
    libreoffice-fresh \
    evince \
    poppler \
    code \
    ncdu \
    wget \
    curl \
    hwinfo \
    mako \
    cryptsetup \
    lvm2 \
    grub \
    zsh \
    os-prober \
    efibootmgr \
    libva-intel-driver \
    flashplugin

# System Configuration
genfstab /mnt >> /mnt/etc/fstab
arch-chroot /mnt echo "${hostname}" > /mnt/etc/hostname
arch-chroot /mnt sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
arch-chroot /mnt ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
arch-chroot /mnt useradd -mU -s /bin/bash -G wheel "${sudo_user}"

# File changes
# mdns_minimal [NOTFOUND=return] ...
# Font config
arch-chroot /mnt ln -s /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
arch-chroot /mnt ln -s /etc/fonts/conf.avail/11-lcdfilter-default.conf /etc/fonts/conf.d
sed -i "/FREETYPE_PROPERTIES/s/^#//g" /mnt/etc/profile.d/freetype2.sh
cat <<EOF > /mnt/etc/fonts/local.conf 
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <match>
        <edit mode="prepend" name="family"><string>Noto Sans</string></edit>
    </match>
    <match target="pattern">
        <test qual="any" name="family"><string>serif</string></test>
        <edit name="family" mode="assign" binding="same"><string>Noto Serif</string></edit>
    </match>
    <match target="pattern">
        <test qual="any" name="family"><string>sans-serif</string></test>
        <edit name="family" mode="assign" binding="same"><string>Noto Sans</string></edit>
    </match>
    <match target="pattern">
        <test qual="any" name="family"><string>monospace</string></test>
        <edit name="family" mode="assign" binding="same"><string>Noto Mono</string></edit>
    </match>
</fontconfig>
EOF

# Firewall Rules
## Defaults
arch-chroot /mnt ufw default deny
arch-chroot /mnt ufw enable

## VPN settings
# TODO: get DEFAULT_FORWARD_POLICY from DROP to ACCEPT

## Samba
cat <<EOF > /mnt/etc/ufw/applications.d/samba
[samba]
title=LanManager-like file and printer server for Unix
description=The Samba software suite is a collection of programs that implements the SMB/CIFS protocol for unix systems, allowing you to serve 
files and printers to Windows, NT, OS/2 and DOS clients. This protocol is sometimes also referred to as the LanManager or NetBIOS protocol.
ports=137,138/udp|139,445/tcp
EOF

# User permissions
echo "${sudo_user} ALL=(ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/${sudo_user}

# Changing passwords
echo "${root_pass}\n${root_pass}" | arch-chroot /mnt passwd
echo "${sudo_user_pass}\n${sudo_user_pass}" | arch-chroot /mnt passwd ${sudo_user} | echo "${sudo_user_pass}"

# Systemd enables
arch-chroot /mnt systemctl enable sshd
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable avahi-daemon.service
arch-chroot /mnt systemctl enable cups.service
arch-chroot /mnt systemctl enable docker
arch-chroot /mnt systemctl enable ufw.service

# Bootloader
# TODO: looking at EFI, but defaulting to GRUB

# GRUB / MBR - Basic install (No EFI) #
grub-install ${disk}
grub-mkconfig -o /boot/grub/grub.cfg

## Start post config ##

# AUR installer
#source aur.sh