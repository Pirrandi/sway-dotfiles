#!/bin/bash
# Claude Code hook: flags the sway window running this Claude session so
# waybar's ctx-workspaces can highlight its workspace.
#
#   claude-ws-mark.sh set    (Stop / Notification) -> mark, unless already focused
#   claude-ws-mark.sh clear  (UserPromptSubmit)    -> unmark
#
# Marks live in $XDG_RUNTIME_DIR/claude-ws/<con_id>; ctx-workspaces.sh renders
# them and drops a mark when its window gets focus. A sway tick event wakes it.
#
# Inside tmux the tmux window is flagged too (@claude_done, unless it is the
# active one); tmux.conf renders it and clears it on session-window-changed.
#
# A soft chime plays only when something gets newly flagged, so it stays silent
# while you are looking at Claude and never repeats for the same window. Drop a claude-done.{ogg,oga,wav,flac,mp3} into
# ~/.local/share/sounds/ to replace the default (a short synthesized tock).
#
# Inside tmux the process tree ends at the tmux server, so the window is found
# through the pids of the tmux clients attached to this session instead.

MARK_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/claude-ws"
DEFAULT_SOUND=$HOME/.config/sounds/claude-done.wav
VOLUME=0.35
ACTION=${1:-set}
flagged=false

cat >/dev/null # drain the hook payload

ancestors() {
    local pid=$1
    while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
        echo "$pid"
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
}

candidate_pids() {
    ancestors "$PPID"
    if [ -n "$TMUX" ]; then
        local session
        session=$(tmux display-message -p -t "${TMUX_PANE:-}" '#{session_name}' 2>/dev/null)
        tmux list-clients -t "$session" -F '#{client_pid}' 2>/dev/null |
            while read -r client; do ancestors "$client"; done
    fi
}

chime() {
    command -v pw-play >/dev/null || return
    local sound
    sound=$(fd -1 -t f '^claude-done\.(ogg|oga|wav|flac|mp3)$' "$HOME/.local/share/sounds" 2>/dev/null)
    sound=${sound:-$DEFAULT_SOUND}
    [ -r "$sound" ] && pw-play --volume "$VOLUME" "$sound" >/dev/null 2>&1 &
}

if [ -n "$TMUX_PANE" ]; then
    case $ACTION in
        set)
            [ "$(tmux display-message -p -t "$TMUX_PANE" '#{window_active},#{@claude_done}')" = 0, ] &&
                tmux set-option -w -t "$TMUX_PANE" @claude_done 1 && flagged=true
            ;;
        clear) tmux set-option -wu -t "$TMUX_PANE" @claude_done ;;
    esac 2>/dev/null
fi

pids=$(candidate_pids | jq -Rsc 'split("\n") | map(select(length > 0) | tonumber)')

window=$(swaymsg -t get_tree -r 2>/dev/null | jq -r --argjson pids "$pids" '
    first(.. | objects | select(.pid? != null and (.pid | IN($pids[]))))
    | "\(.id) \(.focused)"
')
read -r con_id focused <<<"$window"

case $ACTION in
    set)
        if [ -n "$con_id" ] && [ "$focused" != true ] && [ ! -e "$MARK_DIR/$con_id" ]; then
            mkdir -p "$MARK_DIR" && : >"$MARK_DIR/$con_id" && flagged=true
        fi
        $flagged && chime
        ;;
    clear)
        [ -n "$con_id" ] && [ -e "$MARK_DIR/$con_id" ] || exit 0
        rm -f "$MARK_DIR/$con_id"
        ;;
esac

[ -n "$con_id" ] && swaymsg -t send_tick claude-ws >/dev/null 2>&1
exit 0
