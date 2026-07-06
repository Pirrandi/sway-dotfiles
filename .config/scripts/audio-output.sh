#!/bin/bash
# Selector rápido de salida de audio (wofi + pactl)

CURRENT=$(pactl get-default-sink)

declare -A DESC_TO_NAME
OPTIONS=""

while IFS=$'\t' read -r name desc; do
    [ -z "$name" ] && continue
    DESC_TO_NAME["$desc"]="$name"
    if [ "$name" = "$CURRENT" ]; then
        OPTIONS+="🔊 ${desc}\n"
    else
        OPTIONS+="🔈 ${desc}\n"
    fi
done < <(pactl list sinks | awk -F': ' '/^\tName:/ {name=$2} /^\tDescription:/ {desc=$2; print name "\t" desc}')

CHOICE=$(echo -e "$OPTIONS" | wofi --show dmenu --prompt "Salida de audio:" --width 400 --height 250)
[ -z "$CHOICE" ] && exit 0

DESC=$(echo "$CHOICE" | sed 's/^[^ ]* //')
NEW_SINK="${DESC_TO_NAME[$DESC]}"
[ -z "$NEW_SINK" ] && exit 0

pactl set-default-sink "$NEW_SINK"

# Mover streams activos a la nueva salida
pactl list short sink-inputs | while read -r id _; do
    pactl move-sink-input "$id" "$NEW_SINK"
done

pkill -RTMIN+1 waybar
notify-send "Salida de audio" "🔊 ${DESC}" -t 1500
