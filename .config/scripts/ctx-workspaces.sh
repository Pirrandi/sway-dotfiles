#!/bin/bash
CTX_FILE=/tmp/sway-ctx
CTX=$(cat "$CTX_FILE" 2>/dev/null || echo "work")

pairs=$(swaymsg -t get_workspaces | grep -oP '"name": "\K[^"]+|"focused": \K(true|false)' | paste -d' ' - -)

result=""
while read -r name focused; do
    [ -z "$name" ] && continue
    case "$name" in
        "$CTX":*)
            num=$((10#${name#*:}))
            dot="○"
            [ "$focused" = "true" ] && dot="●"
            result+="${dot}${num} "
            ;;
    esac
done < <(echo "$pairs" | sort)

result="${result% }"
echo "$CTX: ${result:-○1}"
