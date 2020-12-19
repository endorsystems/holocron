#!/bin/bash
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

# echo $disk
echo ${disk%%\ *}
echo ${part_boot}
echo ${part_root}

## WORKING ##
# holocron/test_scripts on  main [!?]
# ➜ ./disk_selection.sh
# /dev/sda
# /dev/sda1
# /dev/sda2