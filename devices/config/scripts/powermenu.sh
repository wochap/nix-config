#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Mail : adi1090x@gmail.com
## Github : @adi1090x
## Reddit : @adi1090x

rofi_command="rofi -m 0 -theme /etc/powermenu.rasi"

uptime=$(uptime -p | sed -e 's/up //g')

# Options
shutdown=" Shutdown"
reboot=" Reboot"
# lock=" Bloquear"
# suspend=" Hibernar"
logout=" Logout"

# Variable passed to rofi
options="$logout\n$reboot\n$shutdown"
# options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

chosen="$(echo -e "$options" | $rofi_command -p "UP - $uptime" -dmenu -selected-row 0)"
case $chosen in
    $shutdown)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        ;;
    # $lock)
    #     /home/fhilipe/.config/polybar/scripts/lock.sh
    #     ;;
    # $suspend)
    #     mpc -q pause
    #     amixer set Master mute
    #     systemctl suspend
    #     ;;
    $logout)
        bspc quit
        ;;
esac

