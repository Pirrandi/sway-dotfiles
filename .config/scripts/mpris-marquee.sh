#!/bin/bash
# Custom waybar module: shows the active MPRIS player and scrolls the
# artist/title horizontally when it doesn't fit in WIDTH chars.
WIDTH=22
GAP="   ·   "
DELAY=0.4

json_escape() {
    printf '%s' "$1" | tr -d '\n\r' | sed 's/\\/\\\\/g; s/"/\\"/g'
}

pos=0
last_key=""

while true; do
    player=$(playerctl -l 2>/dev/null | head -n1)
    status=$(playerctl status 2>/dev/null)

    if [ -z "$player" ] || [ -z "$status" ]; then
        echo '{"text":"","class":"stopped"}'
        pos=0
        last_key=""
        sleep 1
        continue
    fi

    artist=$(playerctl metadata artist 2>/dev/null)
    title=$(playerctl metadata title 2>/dev/null)
    text="$title"
    [ -n "$artist" ] && text="$artist - $title"

    key="$player|$text"
    if [ "$key" != "$last_key" ]; then
        pos=0
        last_key="$key"
    fi

    len=${#text}
    if [ "$len" -le "$WIDTH" ]; then
        display="$text"
    else
        loop="${text}${GAP}"
        llen=${#loop}
        start=$((pos % llen))
        end=$((start + WIDTH))
        if [ "$end" -le "$llen" ]; then
            display="${loop:start:WIDTH}"
        else
            part1="${loop:start}"
            part2="${loop:0:end-llen}"
            display="${part1}${part2}"
        fi
        pos=$((pos + 1))
    fi

    icon="▶"
    class="playing"
    if [ "$status" = "Paused" ]; then
        icon="⏸"
        class="paused"
    fi

    text_json=$(json_escape "$icon $display")
    tooltip_json=$(json_escape "$text")
    echo "{\"text\":\"$text_json\",\"class\":\"$class\",\"tooltip\":\"$tooltip_json\"}"

    sleep "$DELAY"
done
