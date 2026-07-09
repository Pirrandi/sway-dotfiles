#!/bin/bash
# Menú de addons togglables (wlsunset, cliphist, no molestar)

is_on() { pgrep -f "$1" >/dev/null; }

sunset_on=$(is_on "wlsunset" && echo on || echo off)
cliphist_on=$(is_on "watch cliphist" && echo on || echo off)
dnd_on=$(makoctl mode 2>/dev/null | grep -q dnd && echo on || echo off)

OPT_SUNSET=" Filtro luz azul"
OPT_CLIPHIST=" Historial portapapeles"
OPT_DND=" No molestar"

OPTIONS="$OPT_SUNSET [$sunset_on]\n$OPT_CLIPHIST [$cliphist_on]\n$OPT_DND [$dnd_on]"

CHOICE=$(echo -e "$OPTIONS" | wofi --show dmenu --prompt "Addons:" --width 300 --height 200)

case "$CHOICE" in
    "$OPT_SUNSET"*)
        if is_on "wlsunset"; then
            pkill -f wlsunset
            notify-send "Filtro luz azul" "Desactivado" -t 1500
        elif ! command -v wlsunset >/dev/null; then
            notify-send "Filtro luz azul" "wlsunset no está instalado (yay -S wlsunset)" -u critical
        else
            wlsunset -S 07:00 -s 20:00 -t 4000 &
            disown
            notify-send "Filtro luz azul" "Activado" -t 1500
        fi
        ;;
    "$OPT_CLIPHIST"*)
        if is_on "watch cliphist"; then
            pkill -f "watch cliphist"
            notify-send "Historial portapapeles" "Desactivado" -t 1500
        elif ! command -v cliphist >/dev/null; then
            notify-send "Historial portapapeles" "cliphist no está instalado (yay -S cliphist)" -u critical
        else
            wl-paste --type text --watch cliphist store &
            disown
            wl-paste --type image --watch cliphist store &
            disown
            notify-send "Historial portapapeles" "Activado" -t 1500
        fi
        ;;
    "$OPT_DND"*)
        if makoctl mode 2>/dev/null | grep -q dnd; then
            makoctl mode -r dnd
            notify-send "No molestar" "Desactivado" -t 1500
        else
            makoctl mode -a dnd
            notify-send "No molestar" "Activado" -t 1500
        fi
        ;;
esac
