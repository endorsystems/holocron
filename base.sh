#!/bin/bash
#
# Holocron Arch Linux installer
#

## Starting this script using simple prompts.
# TODO: Replace with interactive whiptail prompts.
# echo "Laptop or VM / Desktop?"
# read device_type

echo "###########################"
echo "### Welcome to Holocron ###"
echo "###########################"
echo ""

# Device type (laptop, VM, desktop)
# TODO: Create use cases for this.
# echo "Input the type of device. (Laptop, VM, Desktop)"
# read device_type

# Hostname
echo "Please type in the desired hostname."
read hostname
echo ""

# Sudoer
echo "Please enter the name of the super user."
read sudo_user
echo " "

# Sudoer password
echo "Please enter the password for the super user."
read -s sudo_user_pass
echo ""

# Root pw
echo "Please type the password for the root user."
read -s root_pass
echo ""

# # Disk Selection
# echo `lsblk | grep disk`
# echo "Please select from the above disks to use for installation. Make sure its full path '/dev/sda'" 
# read disk
# echo ""
# if [ -z "$disk" ]
# then
#       echo "No disk selected, please restart the script."
#       exit 1
# fi
# read -p "Are you sure? THIS WILL DELETE ALL DATA FROM THE SELECTED DISK! (Yes or No)" -n 1 -r
# echo
# if [[ $REPLY =~ ^[Yy]$ ]]
# then
#     # Unmount just in case
#     umount ${disk}{1..2}
#     # Wipe with DD
#     dd if=/dev/zero of=${disk} bs=1M count=3000
#     # Disk partitioning.
#     parted --script "${disk}" -- mklabel gpt \
#     mkpart ESP fat32 1Mib 513MiB \
#     set 1 boot on \
#     mkpart primary xfs 513MiB 100%
# else
#     exit 2
# fi

# # vars
# # TODO: look into why this isn't showing the right var
# # part_boot="$(lsblk ${disk}* | grep -E "^${disk}p?1$")"
# # part_root="$(lsblk ${disk}* | grep -E "^${disk}p?2$")"

# # TODO: encryption...

# # Formatting
# mkfs.fat -F32 "${disk}1"
# mkfs.xfs -f "${disk}2"

# # Mounting
# mount "${disk}2" /mnt
# mkdir /mnt/boot
# mount "${disk}1" /mnt/boot

## Using templates for either laptop or desktop.
# Package template
# TODO: check this template system out, for now default packages for laptop
# if [[ $device_type == "laptop" ]]
# then
#     # Laptop Template
# fi

# Choice for local network mirror or local usb repo
# Repos will be mounted at /media/archlinux
echo "Would you like to use a local filesystem?"
read local_fs

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

# Package installation
# TODO: Possible package selection of some sort for extras?
source packages/pacstrap.sh

# System Configuration
genfstab -U /mnt > /mnt/etc/fstab
arch-chroot /mnt echo "${hostname}" > /mnt/etc/hostname
arch-chroot /mnt sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
arch-chroot /mnt ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
arch-chroot /mnt useradd -mU -s /usr/bin/zsh -G wheel "${sudo_user}"

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

# SSH server is disabled by default but if its enabled, use rate limiting.
# ufw limit SSH

## VPN settings
# TODO: get DEFAULT_FORWARD_POLICY from DROP to ACCEPT
# Not sure this is needed because with ufw enabled and on VPN with no issues.

## Samba
# TODO: there is an issue with this: 'WARN: Skipping 'samba': couldn't process'
# cat <<EOF > /mnt/etc/ufw/applications.d/samba
# [samba]
# title=LanManager-like file and printer server for Unix
# description=The Samba software suite is a collection of programs that implements the SMB/CIFS protocol for unix systems, allowing you to serve 
# files and printers to Windows, NT, OS/2 and DOS clients. This protocol is sometimes also referred to as the LanManager or NetBIOS protocol.
# ports=137,138/udp|139,445/tcp
# EOF

# User permissions
echo "${sudo_user} ALL=(ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/${sudo_user}

# Changing passwords
echo root:${root_pass} | chpasswd --root /mnt
echo ${sudo_user}:${sudo_user_pass} | chpasswd --root /mnt

# OLD
# echo "${root_pass}\n${root_pass}" | passwd --root /mnt root
# echo "${sudo_user_pass}\n${sudo_user_pass}" | passwd --root /mnt ${sudo_user}

# Systemd enables
arch-chroot /mnt systemctl enable sshd
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable avahi-daemon.service
arch-chroot /mnt systemctl enable cups.service
arch-chroot /mnt systemctl enable docker
arch-chroot /mnt systemctl enable ufw.service

# Bootloader
# EFISTUB install
efi_partuuid=`blkid | grep ${disk}2 | awk -F'"' '{print $10}'` 
arch-chroot /mnt efibootmgr --disk ${disk} --part 1 --create --label "Arch Linux" --loader /vmlinuz-linux --unicode "root=PARTUUID=${efi_partuuid} rw initrd=\initramfs-linux.img" --verbose

## Start post config ##

# AUR installer
#source aur.sh

# Git configs
#source post_setup.sh

# Unmount partitions
umount /dev/sda{1..2}
