#!/bin/sh

# path:       /home/klassiker/.local/share/repos/dmenu/scripts/dmenu_iwd.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/dmenu
# date:       2020-06-08T09:11:53+0200

script=$(basename "$0")
help="$script [-h/--help] -- script to connect to wlan with iwd
  Usage:
    depending on how the script is named,
    it will be executed either with dmenu or with rofi

  Examples:
    dmenu_iwd.sh
    rofi_iwd.sh"

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    printf "%s\n" "$help"
    exit 0
fi

case $script in
    dmenu_*)
        label_interface="interface »"
        menu_interface="wofi -dmenu -no-fixed-num-lines -yoffset -100 -i" 
        # dmenu -l 3 -c -bw 2 -r -i"
        label_ssid="ssid »"
        menu_ssid="wofi -dmenu -no-fixed-num-lines -yoffset -100 -i"
        label_psk="passphrase »"
        menu_psk="wofi -dmenu -no-fixed-num-lines -yoffset -100 -i"
        ;;
    rofi_*)
        label_interface=""
        menu_interface="wofi -no-fixed-num-lines -yoffset -100 -dmenu -i"
        label_ssid=""
        menu_ssid="wofi -no-fixed-num-lines -yoffset -100 -dmenu -i"
        label_psk=""
        menu_psk="wofi -no-fixed-num-lines -yoffset -100 -dmenu -i"
        ;;
    *)
        printf "%s\n" "$help"
        exit 1
        ;;
esac

remove_escape_sequences() {
    tail -n +5 \
        | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g;/^\s*$/d"
}

get_interface() {
    interface=$(iwctl device list \
        | remove_escape_sequences \
        | awk '{print $1" == ["$2"] == ["$3"]"}' \
        | $menu_interface -p "$label_interface" \
        | awk '{print $1}'
    )
    [ -n "$interface" ] \
        || exit 1
}

scan_ssid() {
    iwctl station "$interface" scan && sleep 1
    scan_result=$(iwctl station "$interface" get-networks \
        | remove_escape_sequences \
        | sed 's/ psk / ; [psk ] ; /;s/ open / ; [open] ; /;s/\s\+/ /g' \
        | awk -F " ; " '{print $2" =="$1}' \
    )
}

get_ssid() {
    select=$(printf "[scan] == rescan?\n%s" "$scan_result" \
        | $menu_ssid -p "$label_ssid" \
    )
    ssid=$(printf "%s" "$select" \
        | awk -F" == " '{print $2}' \
    )
    if printf "%s" "$ssid" | grep -q "^> "; then
        notify-send "iNet wireless daemon" "already connected to \"$(printf "%s" "$ssid" \
            | sed 's/> //')\""
        exit 0
    fi
    [ "$(printf "%s" "$select" \
        | awk -F" == " '{print $1}')" = "[open]" ] \
        && open=1
    [ "$select" = "[scan] == rescan?" ] && {
        scan_ssid && sleep 2
        get_ssid
    }
    [ -n "$select" ] \
        || exit 1
}

get_psk() {
    psk=$(printf 'press esc or enter if you had already insert a passphrase before!\n' \
        | $menu_psk -p "$label_psk" \
    )
}

connect_iwd() {
    if [ -z "$open" ]; then
        get_psk
        iwctl station "$interface" connect "$ssid" -P "$psk"
    else
        iwctl station "$interface" connect "$ssid"
    fi
    notify-send "iNet wireless daemon" "connected to \"$ssid\""
}

get_interface \
    && scan_ssid \
    && get_ssid \
    && connect_iwd