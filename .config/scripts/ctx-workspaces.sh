#!/bin/bash
# Waybar custom/ctx-workspaces: workspaces of the active context (work/personal),
# rendered as "work: ●1 ○2 ○3".
#
# Persistent: renders once, then re-renders only on sway workspace events
# instead of forking bash + swaymsg + jq every second. Context switches are
# covered too, because every switch ends in `swaymsg workspace <ctx>:NN`, which
# fires a workspace event after the context file has been written.
#
# CLAUDE: windows flagged by claude-ws-mark.sh (a Claude Code hook) live in
# $MARK_DIR/<con_id>; their workspaces render highlighted with a ✻. The hook
# wakes this loop with a sway tick, and focusing a flagged window clears it.
#
# LIFECYCLE: exits when waybar (the parent) is gone, so reloads don't pile up
# orphaned copies of this script and its `swaymsg -t subscribe` child.

CTX_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sway-ctx"
MARK_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/claude-ws"
PARENT=$PPID

has_marks() { compgen -G "$MARK_DIR/*" >/dev/null; }

# Names of the workspaces holding a flagged window, as a JSON array.
marked_workspaces() {
    has_marks || { echo '[]'; return; }
    local ids
    ids=$(printf '%s\n' "$MARK_DIR"/* | sed 's|.*/||' | jq -Rsc 'split("\n") | map(select(length > 0) | tonumber)')
    swaymsg -t get_tree -r 2>/dev/null | jq -c --argjson ids "$ids" '
        [ .. | objects | select(.type? == "workspace")
          | select(any(.. | objects | .id?; IN($ids[])))
          | .name ]
    ' || echo '[]'
}

# Drops the flag of the window a focus event points at; fails if it had none.
clear_focused() {
    has_marks || return 1
    local id
    id=$(jq -r '.container.id' <<<"$1" 2>/dev/null)
    [ -e "$MARK_DIR/$id" ] || return 1
    rm -f "$MARK_DIR/$id"
}

render() {
    local ctx=""
    [ -r "$CTX_FILE" ] && ctx=$(<"$CTX_FILE")
    ctx=${ctx//[[:space:]]/}
    [ -n "$ctx" ] || ctx=personal

    swaymsg -t get_workspaces -r 2>/dev/null | jq -r --unbuffered --arg ctx "$ctx" \
        --argjson marked "$(marked_workspaces)" '
        [ .[]
          | select(.name | startswith($ctx + ":"))
          | { n: (.name | split(":") | .[1] | tonumber), f: .focused,
              c: (.name | IN($marked[])) }
        ]
        | sort_by(.n)
        | map(. as $w | (if .f then "●" else "○" end) + (.n | tostring)
              | if $w.c then "<span color=\"#d97757\">" + . + "✻</span>" else . end)
        | (if length == 0 then "○1" else join(" ") end)
        | $ctx + ": " + .
    '
}

trap 'pkill -P $$; exit 0' INT TERM HUP EXIT

render
while true; do
    while read -r event; do
        [ -e "/proc/$PARENT" ] || exit 0
        case $event in
            # window focus: only matters when it clears a Claude flag
            '{ "change": "focus", "container"'*) clear_focused "$event" || continue ;;
            # window moved: a flagged one may have changed workspace
            '{ "change": "move", "container"'*) has_marks || continue ;;
            # title changes and the rest of the window noise
            *'"container"'*) continue ;;
        esac
        render || exit 0
    done < <(swaymsg -t subscribe -m '["workspace", "window", "tick"]' 2>/dev/null)
    # sway IPC dropped (sway restart): retry instead of freezing the module
    [ -e "/proc/$PARENT" ] || exit 0
    sleep 1
done
