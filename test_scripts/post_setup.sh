#!/bin/bash
#
# post_setup.sh
#
#

# TODO: This to replace some of the customizations I've placed in the base.sh file.


### sysd setup ###
arch-chroot /mnt systemctl enable avahi-daemon.service
arch-chroot /mnt systemctl enable cups.service
arch-chroot /mnt systemctl enable docker