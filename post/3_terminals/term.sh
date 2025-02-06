#!/bin/sh

# Copyright (C) 2021-2024 Thien Tran
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
source ./post/users.sh

################################################################################
# Terminals
################################################################################

terminals_menu() {
    local title="Terminal configurator."
    local description="This allows you to set up different terminals. Please select the terminal which shall be configured."
    while true; do
        local options=(\
            "Kitty"\
            "Alacritty"\
            "Terminator"\
            "Tilix"\
            "GNOME Terminal"\
            "Konsole"\
            "Back"
        )
        menu_prompt term_choice "$title" "$description" "${options[@]}"
        case $term_choice in
            0)  configure_kitty;;
            1)  configure_alacritty;;
            2)  configure_terminator;;
            3)  configure_tilix;;
            4)  configure_gnome_terminal;;
            5)  configure_konsole;;
            b)  break;;
            *)  echo "Invalid option. Please try again.";;
        esac
    done
}


configure_kitty() {
    install_pacman_packages kitty
    continue_script 2 "Kitty installed" "Kitty installed correctly"
}
configure_alacritty() {
    install_pacman_package alacritty
    continue_script 2 "Alacritty installed" "Alacritty installed correctly"
}
configure_terminator() {
    install_pacman_package terminator
    continue_script 2 "Terminator installed" "Terminator installed correctly"
}
configure_tilix() {
    install_pacman_package tilix
    continue_script 2 "Tilix installed" "Tilix installed correctly"
}
configure_gnome_terminal() {
    install_pacman_package gnome-terminal
    continue_script 2 "Gnome-terminal installed" "Gnome-terminal installed correctly"
}
configure_konsole() {
    install_pacman_package konsole
    continue_script 2 "Konsole installed" "Konsole installed correctly"
}
