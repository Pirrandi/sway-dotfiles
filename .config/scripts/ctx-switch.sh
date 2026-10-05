#!/bin/bash
# Switch to context $1, landing on the last workspace used in it (or :01).
# Optional $2 forces a specific workspace number in the target context.
#
# Before leaving, the focused workspace is recorded as the last one of the
# current context, so coming back restores it instead of resetting to :01.

RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
CTX_FILE="$RUNTIME/sway-ctx"
LAST_DIR="$RUNTIME/sway-ctx-last"

TARGET=$1
# Letters only: the name is interpolated into sway commands and file paths
[[ "$TARGET" =~ ^[a-zA-Z]+$ ]] || exit 1

mkdir -p "$LAST_DIR"

CURRENT=$(cat "$CTX_FILE" 2>/dev/null)
FOCUSED=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .name')
if [ -n "$CURRENT" ] && [[ "$FOCUSED" == "$CURRENT:"* ]]; then
    echo "$FOCUSED" > "$LAST_DIR/$CURRENT"
fi

if [ -n "$2" ]; then
    WS="$TARGET:$(printf "%02d" "$((10#$2))")"
else
    WS=$(cat "$LAST_DIR/$TARGET" 2>/dev/null)
    [[ "$WS" == "$TARGET:"* ]] || WS="$TARGET:01"
fi

echo "$TARGET" > "$CTX_FILE"
swaymsg "workspace $WS" >/dev/null
notify-send "Contexto" "📁 $WS" -t 1500
