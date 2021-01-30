# holocron
Script(s) to install Arch Linux from ISO

TODO:
- Create a Custom ISO with scripts installed for offline use
-- Add Ansible to the ISO to help with post config

## Post Config
Ansible based. Requires: ansible-galaxy install kewlfft.aur (run by base.sh)
https://github.com/kewlfft/ansible-aur.git
<!-- # Do I want these?
  # - tumbler
  # - evince
  # - poppler
  # - ncdu
  # - duplicity -->

## Credits
I believe credit where credit is due, it also helps other people understand whats in there. Here are the sources for my thought process on this.
- A complete install script, sourced some ideas and thoughts from this.
https://disconnected.systems/blog/archlinux-installer/#the-complete-installer-script
- Whiptail docs
https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail
- AUR ansible module
https://github.com/kewlfft/ansible-aur.git


## Git sources
- My personal dotfiles (sway / i3 themes)
https://github.com/endorsystems/dotfiles
- Dracula, used for a lot of the themes. (alacritty, i3, sway, wofi, rofi, dunst, xresources, etc...)
https://github.com/dracula/dracula-theme

## TODO List

- I'm trying to perfect the final installed version.
Problems I'm having.

- bluetooth connecting and using.
- icon consistancy
- font consistancy
- wm and de, login page and lock screen with timeout
- speed and stability
- steam?
