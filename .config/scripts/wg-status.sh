#!/bin/bash
PROFILES=(cl-scl-wg-001 peer5 peer9)

# One `systemctl is-active` call for every profile at once instead of one per
# profile: this runs on the waybar poll, so it is the hot path of this script.
active_profile() {
    local units=() states=() i
    for p in "${PROFILES[@]}"; do units+=("wg-quick@${p}.service"); done
    mapfile -t states < <(systemctl is-active "${units[@]}" 2>/dev/null)
    for i in "${!PROFILES[@]}"; do
        if [ "${states[i]}" = "active" ]; then
            echo "${PROFILES[i]}"
            return
        fi
    done
}

# Byte count to human units in pure bash — `numfmt` was two extra forks per poll.
human() {
    local b=$1 u=(B K M G T) i=0 frac=0
    [[ $b =~ ^[0-9]+$ ]] || { printf 'n/d'; return; }
    while [ "$b" -ge 1024 ] && [ "$i" -lt 4 ]; do
        frac=$(( (b % 1024) * 10 / 1024 ))
        b=$(( b / 1024 ))
        i=$(( i + 1 ))
    done
    if [ "$i" -eq 0 ]; then
        printf '%dB' "$b"
    else
        printf '%d.%d%s' "$b" "$frac" "${u[i]}"
    fi
}

status() {
    local active transfer rx tx rx_h tx_h
    active=$(active_profile)
    if [ -z "$active" ]; then
        echo '{"text":"vpn off","tooltip":"VPN desconectada","class":"disconnected"}'
        return
    fi
    transfer=$(sudo -n wg show "$active" transfer 2>/dev/null)
    read -r _ rx tx _ <<<"$transfer"
    rx_h=$(human "$rx")
    tx_h=$(human "$tx")
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
            target=${choice#[●○]  }
            [ -n "$target" ] && switch_to "$target"
            ;;
    esac
}

case "${1:-status}" in
    status) status ;;
    menu) menu ;;
esac
