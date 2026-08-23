#!/bin/bash
# Waybar custom/mpris: shows the active MPRIS player and scrolls the
# artist/title horizontally when it doesn't fit in WIDTH chars.
#
# Event-driven: `playerctl --follow` pushes one line per status/metadata change,
# so this loop only wakes up to advance the marquee on long titles, and idles
# on a slow heartbeat while nothing is playing. The previous version polled four
# separate `playerctl` processes plus `sed`/`tr` every 0.4s, measured at ~28ms
# per tick (~7% of one core) burning permanently even when the text was static.
#
# LIFECYCLE: a persistent module must die with waybar, otherwise every waybar
# restart (sway reload, crash, RTMIN handling) orphans this script plus its
# `playerctl --follow` child, and they pile up as ppid=1 zombies forever. Two
# guards: we check the parent is still alive, and the idle heartbeat re-render
# makes writes fail with SIGPIPE once waybar's end of the pipe is gone.

WIDTH=22
GAP="   ·   "
DELAY=0.4
HEARTBEAT=60
FMT='{{status}}|{{artist}}|{{title}}'
PARENT=$PPID

status=""
text=""
pos=0
scrolling=0

# Do NOT use $! to track the feeder: for `exec {fd}< <(cmd)` bash sets $! to a
# wrapper subshell that has already exited by cleanup time, while `cmd` itself
# runs as a separate direct child — killing $! leaves the real `swaymsg` /
# `playerctl` behind as a ppid=1 orphan. Reap our actual children instead.
kill_tree() {
    local pid=$1 kid
    [ -n "$pid" ] || return
    for kid in $(pgrep -P "$pid" 2>/dev/null); do
        kill_tree "$kid"
    done
    kill "$pid" 2>/dev/null
}
kill_children() {
    local kid
    for kid in $(pgrep -P $$ 2>/dev/null); do
        kill_tree "$kid"
    done
}
# A signal trap that does not exit leaves bash running: the handler reaped the
# feeder child and the loop just carried on, so the script survived SIGTERM and
# waybar could never stop it. Signals must terminate; EXIT only reaps.
on_signal() { kill_children; exit 0; }
trap kill_children EXIT
trap on_signal INT TERM HUP

emit() {
    local body=$1 cls=$2 tip=$3
    body=${body//\\/\\\\}; body=${body//\"/\\\"}
    tip=${tip//\\/\\\\}; tip=${tip//\"/\\\"}
    printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$body" "$cls" "$tip"
}

parse() {
    local artist title new
    IFS='|' read -r status artist title <<<"$1"
    new=$title
    [ -n "$artist" ] && new="$artist - $title"
    if [ "$new" != "$text" ]; then
        text=$new
        pos=0
    fi
}

render() {
    scrolling=0

    if [ -z "$status" ] || [ "$status" = "Stopped" ] || [ -z "$text" ]; then
        emit "" "stopped" ""
        return
    fi

    local display icon cls len loop llen start end
    len=${#text}
    if [ "$len" -le "$WIDTH" ]; then
        display=$text
    else
        loop="${text}${GAP}"
        llen=${#loop}
        start=$(( pos % llen ))
        end=$(( start + WIDTH ))
        if [ "$end" -le "$llen" ]; then
            display="${loop:start:WIDTH}"
        else
            display="${loop:start}${loop:0:end-llen}"
        fi
        pos=$(( pos + 1 ))
        scrolling=1
    fi

    icon="▶"
    cls="playing"
    if [ "$status" = "Paused" ]; then
        icon="⏸"
        cls="paused"
    fi

    emit "$icon $display" "$cls" "$text"
}

while true; do
    exec {fd}< <(playerctl --follow --format "$FMT" metadata 2>/dev/null)

    while true; do
        [ -e "/proc/$PARENT" ] || exit 0
        render
        if [ "$scrolling" = 1 ]; then timeout=$DELAY; else timeout=$HEARTBEAT; fi
        read -r -t "$timeout" -u "$fd" line
        rc=$?
        if [ "$rc" -eq 0 ]; then
            parse "$line"
        elif [ "$rc" -le 128 ]; then
            break           # playerctl ended: D-Bus session dropped
        fi
        # rc > 128 is the read timing out: nothing new, just advance the marquee
        # (or re-emit the idle heartbeat, which is what catches a dead waybar).
    done

    exec {fd}<&-
    kill_children
    status=""; text=""; pos=0
    emit "" "stopped" ""
    sleep 2
done
