#!/bin/bash
PROFILES_DIR="$HOME/.config/wireguard-profiles"
mapfile -t PROFILES < <(find "$PROFILES_DIR" -maxdepth 1 -name '*.conf' -printf '%f\n' 2>/dev/null | sed 's/\.conf$//' | sort)

active_profile() {
    local up
    up=$(ip -o link show type wireguard 2>/dev/null | awk -F': ' '{print $2}')
    for p in "${PROFILES[@]}"; do
        if grep -qx "$p" <<< "$up"; then
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
    local rx tx rx_h tx_h
    rx=$(cat "/sys/class/net/$active/statistics/rx_bytes" 2>/dev/null)
    tx=$(cat "/sys/class/net/$active/statistics/tx_bytes" 2>/dev/null)
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
        sudo -n wg-quick down "$PROFILES_DIR/$active.conf"
    fi
    if [ "$active" != "$target" ]; then
        sudo -n wg-quick up "$PROFILES_DIR/$target.conf"
        notify-send "VPN" "Conectado a ${target}" -t 1500
    fi
    pkill -RTMIN+2 waybar
}

disconnect() {
    local active
    active=$(active_profile)
    if [ -n "$active" ]; then
        sudo -n wg-quick down "$PROFILES_DIR/$active.conf"
        notify-send "VPN" "Desconectado" -t 1500
    fi
    pkill -RTMIN+2 waybar
}

menu() {
    local lockfile="/tmp/wg-status-menu.lock"
    exec 200>"$lockfile"
    flock -n 200 || exit 0

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
