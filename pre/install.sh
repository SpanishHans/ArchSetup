#!/bin/bash

# Copyright (C) 2021-2024 Thien Tran, Tommaso Chiti
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

source ./commons.sh

source ./pre/0_disk/disk_setup.sh
source ./pre/1_networking/networking.sh
source ./pre/2_locales/locales.sh
source ./pre/3_users/users.sh

if [ "$LIVE_ENV" = false ]; then
    pause_script "ERROR" "The install script must be run from the archlinux-YEAR.MONTH.DAY-x86_64.iso image.

Exiting!!!
    "
    exit
    if [ "$(id -u)" -ne 0 ]; then
        pause_script "ERROR" "The install script must be run as root user.

Exiting!!!"
        exit
    fi
fi

start_disk_setup || { pause_script "Error on disk setup" "start_disk failed. Exiting.";exit;}

commands_to_run=()

continue_script 'Detect CPU vendor' 'Detecting ucode for processor brand'
CPU=$(grep -m 1 'vendor_id' /proc/cpuinfo)
if [[ "${CPU}" == *"AuthenticAMD"* ]]; then
    continue_script 'AMD detected' 'Installing ucode for AMD'
    microcode="amd-ucode"
elif [[ "${CPU}" == *"GenuineIntel"* ]]; then
    microcode="intel-ucode"
    continue_script 'Intel detected' 'Installing ucode for Intel'
else
    echo "Unknown CPU vendor. Exiting."
    exit 1
fi

continue_script 'Installing base system' 'Installing the base system (it may take a while).'
commands_to_run+=("pacstrap /mnt\
  base\
  linux\
  linux-firmware\
  "$microcode"\
  btrfs-progs\
  grub\
  efibootmgr\
  sudo\
  polkit\
  networkmanager\
  firewalld\
  openssh\
  nano\
  tree\
  less\
  wayland\
  pipewire\
  wireplumber\
  pipewire-alsa\
  pipewire-pulse\
  pipewire-jack\
  git\
  dialog\
  usbutils\
  debugedit\
  fakeroot\
  ")

commands_to_run+=("genfstab -U /mnt >> /mnt/etc/fstab")

live_command_output "" "" "yes" "Installing linux to disk" "${commands_to_run[@]}"

networking_setup
locales_setup
user_setup

cp -R --no-preserve=ownership /root/Archsetup /mnt/root/Archsetup

description="About to chroot into the machine
this automatically:
    1. Generates locales and configures time to UTC
    2. Enables NetworkManager
    3. Changes root password.
    4. Enable pacman color
    5. Sets up wheel group and adds the admin user to wheel
    6. Grub no timeout and splash quiet
    7. Creates initramfs with mkinitcpio -P
    8. Installs grub for the system with btrfs and snapper-rollback support"
    
continue_script 5 'Chroot description' "$description"

step_1_locales(){
    echo '#### STARTING 1. #### ->> Time and locales'
    ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
    hwclock --systohc
    locale-gen || { echo 'locale-gen failed'; exit 1; }
}

step_2_network(){
    echo '#### STARTING 2. #### ->> Enabling NetworkManager'
    systemctl enable NetworkManager || { echo 'NetworkManager enabling failed'; exit 1; }
}

step_3_passwords(){
    echo '#### STARTING 3. #### ->> Users and passwords'
    useradd -c "Sysadmin" -m sysadmin || { echo 'useradd failed'; exit 1; }
    echo "root:$root_password" | chpasswd || { echo 'root password set failed'; exit 1; }
    echo "sysadmin:$sysadmin_password" | chpasswd || { echo 'sysadmin password set failed'; exit 1; }
}

step_4_pacman_color(){
    echo '#### STARTING 4. #### ->> Configure pacman color'
    sed -i 's/^#Color/Color/' /etc/pacman.conf || { echo 'Failed to configure pacman color'; exit 1; }
}

step_5_sudoers(){
    echo '#### STARTING 5. #### ->> Configure sudoers'
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers || { echo 'Failed to configure sudoers'; exit 1; }
}

step_6_quiet_splash(){
    echo '#### STARTING 6. #### ->> No timeout grub and quiet splash'
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub || { echo 'Failed to set GRUB timeout'; exit 1; }
    sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=\)\".*\"/\1\"quiet splash\"/' /etc/default/grub || { echo 'Failed to set GRUB quiet splash'; exit 1; }
}

step_7_initramfs(){
    echo '#### STARTING 7. #### ->> Initramfs'
    mkinitcpio -P || { echo 'mkinitcpio failed during initramfs creation'; exit 1; }
}

step_8_grub(){
    echo '#### STARTING 8. #### ->> grub-install'
    grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=GRUB || { echo 'grub-install failed'; exit 1; }
    grub-mkconfig -o /boot/grub/grub.cfg || { echo 'grub-mkconfig failed'; exit 1; }
}

commands_to_run=()
commands_to_run+=("step_1_locales")
commands_to_run+=("step_2_network")
commands_to_run+=("step_3_passwords")
commands_to_run+=("step_4_pacman_color")
commands_to_run+=("step_5_sudoers")
commands_to_run+=("step_6_quiet_splash")
commands_to_run+=("step_7_initramfs")
commands_to_run+=("step_8_grub")
live_command_output "" "" "yes" "executing arch-chroot steps" "${commands_to_run[@]}"

pause_script 'Finished' 'Done, you may now wish to reboot (further changes can be done by chrooting into /mnt).'
