#!/bin/bash
# Waybar custom/ctx-workspaces: workspaces of the active context (work/personal),
# rendered as "work: ●1 ○2 ○3".
#
# Persistent: renders once, then re-renders only on sway workspace events
# instead of forking bash + swaymsg + jq every second. Context switches are
# covered too, because every switch ends in `swaymsg workspace <ctx>:NN`, which
# fires a workspace event after the context file has been written.
#
# LIFECYCLE: exits when waybar (the parent) is gone, so reloads don't pile up
# orphaned copies of this script and its `swaymsg -t subscribe` child.

CTX_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sway-ctx"
PARENT=$PPID

render() {
    local ctx=""
    [ -r "$CTX_FILE" ] && ctx=$(<"$CTX_FILE")
    ctx=${ctx//[[:space:]]/}
    [ -n "$ctx" ] || ctx=personal

    swaymsg -t get_workspaces -r 2>/dev/null | jq -r --unbuffered --arg ctx "$ctx" '
        [ .[]
          | select(.name | startswith($ctx + ":"))
          | { n: (.name | split(":") | .[1] | tonumber), f: .focused }
        ]
        | sort_by(.n)
        | map((if .f then "●" else "○" end) + (.n | tostring))
        | (if length == 0 then "○1" else join(" ") end)
        | $ctx + ": " + .
    '
}

trap 'pkill -P $$; exit 0' INT TERM HUP EXIT

render
while true; do
    while read -r _; do
        [ -e "/proc/$PARENT" ] || exit 0
        render || exit 0
    done < <(swaymsg -t subscribe -m '["workspace"]' 2>/dev/null)
    # sway IPC dropped (sway restart): retry instead of freezing the module
    [ -e "/proc/$PARENT" ] || exit 0
    sleep 1
done
