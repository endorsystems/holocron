# minimal install for virtual environment.

import archinstall

__packages__ = [
    "vim",
]

# Start by defining partitions and mountpoints for installation
# This is usually '/mnt/'
def install_on (mountpoint):
    with archinstall.Installer(mountpoint) as installation:
        if installation.minimal_installation():
            installation.set_hostname('vm01')
            installation.add_bootloader()

            installation.add_additional_packages(__packages__)
            installation.install_profile('minimal')

            installation.user_create('sean', 'monkeys')
            installation.user_set_pw('root', 'monkeys')

if archinstall.arguments['harddrive']:
    archinstall.arguments['harddrive'].keep_partitions = False
    