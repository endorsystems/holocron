#!/bin/bash
#
# Holocron Arch Linux installer
#

## Starting this script using simple prompts.
# TODO: Replace with interactive whiptail prompts.
# echo "Laptop or VM / Desktop?"
# read device_type

echo "#######################"
echo "### Welcome to Holocron ###"
echo "#######################"
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

### Set up logging ###
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")

### Time settings ###
timedatectl set-ntp true

# # Disk Selection
items=$(lsblk -d -p -n -l -o NAME,SIZE -e 7,11)
options=()
IFS_ORIG=$IFS
IFS=$'\n'
for item in ${items}
do  
        options+=("${item}" "")
done
IFS=$IFS_ORIG
disk=$(whiptail --backtitle "${APPTITLE}" --title "${1}" --menu "" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3)
if [ "$?" != "0" ]
then
    return 1
fi

part_boot="$(ls ${disk%%\ *}* | grep -E "^${disk%%\ *}p?1$")"
part_root="$(ls ${disk%%\ *}* | grep -E "^${disk%%\ *}p?2$")"

# # Formatting
mkfs.fat -F32 "${part_boot}"
mkfs.xfs -f "${part_root}"

# # Mounting
mount "${part_root}" /mnt
mkdir /mnt/boot
mount "${part_boot}" /mnt/boot

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

### PACKAGE INSTALL ###
# Using a base install to get the system ready, then a Ansible will be used.
# This will allow the user more accurate selection of items.

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
    ufw \
    git \
    openssh \
    rsync \
    dmidecode \
    wget \
    curl \
    hwinfo \
    zsh \
    efibootmgr \
    grub \
    os-prober

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

# User permissions
echo "${sudo_user} ALL=(ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/${sudo_user}

# Changing passwords
echo root:${root_pass} | chpasswd --root /mnt
echo ${sudo_user}:${sudo_user_pass} | chpasswd --root /mnt

# OLD
# echo "${root_pass}\n${root_pass}" | passwd --root /mnt root
# echo "${sudo_user_pass}\n${sudo_user_pass}" | passwd --root /mnt ${sudo_user}

# Systemd enables
# arch-chroot /mnt systemctl enable sshd
arch-chroot /mnt systemctl enable avahi-daemon.service
arch-chroot /mnt systemctl enable cups.service
arch-chroot /mnt systemctl enable docker
arch-chroot /mnt systemctl enable ufw.service

# Bootloader
# EFISTUB install
efi_partuuid=`blkid | grep ${disk}2 | awk -F'"' '{print $10}'` 
arch-chroot /mnt efibootmgr --disk ${disk} --part 1 --create --label "Arch Linux" --loader /vmlinuz-linux --unicode "root=PARTUUID=${efi_partuuid} rw initrd=\initramfs-linux.img" --verbose

## Start post config ##

# Unmount partitions
umount /dev/sda{1..2}
