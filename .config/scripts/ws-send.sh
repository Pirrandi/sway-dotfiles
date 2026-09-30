#!/bin/bash
# Move the focused window to any workspace of any context.
# Names must match ws.sh exactly ("<ctx>:NN"), otherwise sway creates a
# parallel workspace (work:1 next to work:01).
CONTEXTS_FILE=$HOME/.config/scripts/contexts.txt

OPTIONS=""
while IFS= read -r ctx; do
    [ -z "$ctx" ] && continue
    for i in $(seq -w 1 10); do
        OPTIONS+="${ctx}:${i}\n"
    done
done < <(cat "$CONTEXTS_FILE" 2>/dev/null || printf 'personal\nwork\n')

TARGET=$(echo -e "${OPTIONS%\\n}" | wofi --show dmenu --prompt "Mover a:")
[ -n "$TARGET" ] && swaymsg "move container to workspace $TARGET"
