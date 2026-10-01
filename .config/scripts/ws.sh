#!/bin/bash
CTX_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sway-ctx"
CTX=$(cat "$CTX_FILE" 2>/dev/null || echo "personal")
NUM=$(printf "%02d" "$1")
swaymsg "workspace ${CTX}:${NUM}"
