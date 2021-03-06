#!/bin/bash
#
# Holocron Arch Linux installer
#

# Script welcome page

whiptail --title "Holocron" --msgbox "Welcome to Holocron, automated install of Arch Linux.\nThis script also has Ansible for post install dotfiles and stuff." 8 78

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
sudo_user=$(whiptail --inputbox "Please type a username for sudo user." 8 39  --title "Sudo User" 3>&1 1>&2 2>&3)
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

# Create partitions
# EFI boot 512M (EFI/FAT32)
# swap 2G (SWAP)
# root 40G (XFS)
# home (remainder) 

parted --script "${disk%%\ *}" -- mklabel gpt \
  mkpart ESP fat32 1Mib 513MiB \
  set 1 boot on \
  mkpart swap 513MiB 2561MiB \
  mkpart primary xfs 2561MiB 43521MiB \
  mkpart primary xfs 43521MiB 100%

# Assign vars to partitions
part_boot="$(ls ${disk%%\ *}* | grep -E "^${disk%%\ *}p?1$")"
part_swap="$(ls ${disk%%\ *}* | grep -E "^${disk%%\ *}p?2$")"
part_root="$(ls ${disk%%\ *}* | grep -E "^${disk%%\ *}p?3$")"
part_home="$(ls ${disk%%\ *}* | grep -E "^${disk%%\ *}p?4$")"

# Formatting
mkfs.fat -F32 "${part_boot}"
mkfs.xfs -f "${part_root}"
mkfs.xfs -f "${part_home}"
mkswap "${part_swap}"

# Mounting
swapon "${part_swap}"
mount "${part_root}" /mnt
mkdir -p /mnt/boot
mkdir -p /mnt/home
mount "${part_boot}" /mnt/boot
mount "${part_home}" /mnt/home

### REPO SETUP ###
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

# TODO: create verifications prior to installation.
# this prevents the script from free running.

# if grep -qs '/mnt/' /proc/mounts; then
#     whiptail --title "Drive Mount Verification" --msgbox "/mnt is mounted, select ok to continue." 8 78
# else
#     whiptail --title "Drive Mount Verification" --msgbox "/mnt is NOT mounted, select ok to exit." 8 78
#     exit 0
# fi

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
    networkmanager \
    iwd \
    git \
    openssh \
    rsync \
    dmidecode \
    wget \
    curl \
    hwinfo \
    zsh \
    efibootmgr \
    refind \
    os-prober \
    ansible

# System Configuration
genfstab -U /mnt > /mnt/etc/fstab
arch-chroot /mnt echo "${hostname}" > /mnt/etc/hostname
arch-chroot /mnt sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
arch-chroot /mnt ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
arch-chroot /mnt useradd -mU -s /usr/bin/zsh -G wheel "${sudo_user}"

# Firewall Rules
## Defaults
arch-chroot /mnt ufw default deny
arch-chroot /mnt ufw enable

# SSH is disabled by default but if its enabled, use rate limiting.
# ufw limit SSH

## VPN settings
# Sometimes VPN doesn't work by default use the following to help get it working.
# DEFAULT_FORWARD_POLICY from DROP to ACCEPT

# User permissions
echo "${sudo_user} ALL=(ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/${sudo_user}

# Changing passwords
echo root:${root_pass} | chpasswd --root /mnt
echo ${sudo_user}:${sudo_user_pass} | chpasswd --root /mnt

# Systemd enables
# arch-chroot /mnt systemctl enable sshd
arch-chroot /mnt systemctl enable ufw.service
arch-chroot /mnt systemctl enable NetworkManager

# Bootloader
# TODO: figure out bootloader mess. EFISTUB isn't even working on Dell or VMware. Defaulting to grub because of this.
# Looks like booting from refind and setting up in ramdisk is troublesome. 
# I will be installing grub efi and replacing it with refind with the post install.
# explore refined
# EFISTUB install
# efi_partuuid=`blkid | grep ${part_root} | awk -F'"' '{print $10}'` 
# arch-chroot /mnt efibootmgr --disk ${disk} --part 1 --create --label "Arch Linux" --loader /vmlinuz-linux --unicode "root=PARTUUID=${efi_partuuid} rw initrd=\initramfs-linux.img" --verbose

# refind setup
# if additional drivers are requried for kernel
# Use: --alldrivers
efi_partuuid=$(blkid | grep ${part_root} | awk -F'"' '{print $10}')
arch-chroot /mnt refind-install
cat <<EOF > /mnt/boot/refind_linux.conf
"Boot using default options"     "rw root=PARTUUID=${efi_partuuid} add_efi_memmap"
"Boot using fallback initramfs"  "root=PARTUUID=${efi_partuuid} rw add_efi_memmap initrd=boot\initramfs-%v-fallback.img"
"Boot to terminal"               "root=PARTUUID=${efi_partuuid} rw add_efi_memmap initrd=boot\initramfs-%v.img systemd.unit=multi-user.target"
EOF

# GRUB
# arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
# arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

## Start post config ##
# TODO: Insert scripts to be run at login? Or maunal executions?
cp -R ~/holocron /mnt/home/sean/
arch-chroot /mnt chown -R sean:sean /home/sean/holocron

### Reboot ###
if (whiptail --title "Finished?" --yesno "Are you done with the ISO/Installation?" 8 78); then
    umount ${part_boot}
    umount ${part_home}
    umount ${part_root}
    reboot
else
    echo "User canceled, dropping to shell."
    exit 1
fi
