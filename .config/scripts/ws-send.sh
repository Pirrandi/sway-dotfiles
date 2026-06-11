#!/bin/bash
TARGET=$(echo -e "work:1\nwork:2\nwork:3\nwork:4\nwork:5\npersonal:1\npersonal:2\npersonal:3\npersonal:4\npersonal:5" | wofi --show dmenu --prompt "Mover a:")
[ -n "$TARGET" ] && swaymsg "move container to workspace $TARGET"
