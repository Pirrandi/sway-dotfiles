#!/bin/bash
PROFILES=(cl-scl-wg-001 peer5 peer9)

active_profile() {
    for p in "${PROFILES[@]}"; do
        if systemctl is-active --quiet "wg-quick@${p}.service"; then
            echo "$p"
            return
        fi
    done
}

status() {
    local active
    active=$(active_profile)
    if [ -z "$active" ]; then
        echo '{"text":"vpn off","tooltip":"VPN desconectada","class":"disconnected"}'
        return
    fi
    local transfer rx tx rx_h tx_h
    transfer=$(sudo -n wg show "$active" transfer 2>/dev/null)
    rx=$(echo "$transfer" | awk '{print $2}')
    tx=$(echo "$transfer" | awk '{print $3}')
    rx_h="n/d"
    tx_h="n/d"
    [ -n "$rx" ] && rx_h=$(numfmt --to=iec --suffix=B "$rx")
    [ -n "$tx" ] && tx_h=$(numfmt --to=iec --suffix=B "$tx")
    echo "{\"text\":\"vpn ${active}\",\"tooltip\":\"↓ ${rx_h}   ↑ ${tx_h}\",\"class\":\"connected\"}"
}

switch_to() {
    local target="$1"
    local active
    active=$(active_profile)
    if [ -n "$active" ] && [ "$active" != "$target" ]; then
        sudo -n systemctl stop "wg-quick@${active}.service"
    fi
    if [ "$active" != "$target" ]; then
        sudo -n systemctl start "wg-quick@${target}.service"
        notify-send "VPN" "Conectado a ${target}" -t 1500
    fi
    pkill -RTMIN+2 waybar
}

disconnect() {
    local active
    active=$(active_profile)
    if [ -n "$active" ]; then
        sudo -n systemctl stop "wg-quick@${active}.service"
        notify-send "VPN" "Desconectado" -t 1500
    fi
    pkill -RTMIN+2 waybar
}

menu() {
    local active options choice target
    active=$(active_profile)
    options=""
    for p in "${PROFILES[@]}"; do
        if [ "$p" == "$active" ]; then
            options+="●  ${p}\n"
        else
            options+="○  ${p}\n"
        fi
    done
    options+="⏻  Desconectar"

    choice=$(echo -e "$options" | wofi --show dmenu --prompt "VPN:" --width 300 --height 250)

    case "$choice" in
        "⏻  Desconectar")
            disconnect
            ;;
        *)
            target=$(echo "$choice" | sed -E 's/^[●○]  //')
            [ -n "$target" ] && switch_to "$target"
            ;;
    esac
}

case "${1:-status}" in
    status) status ;;
    menu) menu ;;
esac
